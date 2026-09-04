import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, SocketException, HttpException, HandshakeException, TlsException;
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/models/kiosko_config.dart';
import 'package:kigo_kiosco/core/services/coincidencia_facial_local.dart';
import 'package:kigo_kiosco/core/services/connectivity_service.dart';
import 'package:kigo_kiosco/core/services/local_cache_db.dart';
import 'package:kigo_kiosco/core/services/qr_firma_verificador.dart';
import 'package:kigo_kiosco/features/activacion/models/device_solicitud.dart';
import 'package:kigo_kiosco/features/registro/services/resolucion_qr_offline.dart';

class DeviceNotActivatedException implements Exception {}

/// Resultado de un intento de re-login silencioso -- ver KioskoServicio._reLogin.
enum _ReLoginResultado { exito, rechazado, errorDeRed }

/// Token de invitación inválido, expirado, agotado o ya consumido. Tipado
/// aparte (en vez de un Exception genérico) para que SyncWorker pueda
/// distinguirlo de un fallo de red al reproducir un registro offline — este
/// es un rechazo legítimo del backend, no algo que deba reintentarse.
class InvitacionInvalidaException implements Exception {
  final String mensaje;
  InvitacionInvalidaException([this.mensaje = 'Invitación no válida, expirada o agotada']);
  @override
  String toString() => mensaje;
}

class DeviceAuthorizationPendingException implements Exception {}

class DeviceExpiredException implements Exception {}

class KioskoServicio {
  static const String _baseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1';
  static const String _keyToken = 'kiosko_token';
  static const String _keyKioskoId = 'kiosko_id';
  static const String _keyClave = 'kiosko_clave';
  static const String _keyTelefonoContacto = 'kiosko_telefono_contacto';
  static const String _keyConfigRespaldo = 'kiosko_config_respaldo';

  static final KioskoServicio _instance = KioskoServicio._internal();
  factory KioskoServicio() => _instance;
  KioskoServicio._internal();

  final _storage = const FlutterSecureStorage();

  String? _sessionToken;
  int? _kioskoId;

  final _uuid = const Uuid();
  ConnectivityService? _connectivity;
  LocalCacheDb? _cache;

  /// Ultima config conocida, guardada al vuelo tanto del GET inicial como
  /// del SSE. El match facial offline la necesita para el umbral, y ese
  /// camino no tiene por donde recibirla: lo dispara
  /// KioskoServicio.verificarRostroResidente, no una vista con acceso al
  /// KioskoConfigNotifier. Antes el umbral estaba clavado en 0.85 y el
  /// valor del dashboard no lo tocaba nadie.
  KioskoConfig _ultimaConfig = KioskoConfig.defaults;

  /// Piso duro del umbral facial. Una similitud coseno por debajo de esto no
  /// distingue dos caras distintas, asi que un valor menor solo puede venir
  /// de una fila vieja o de un dedazo — y aceptarlo abriria la puerta a
  /// cualquiera. El campo vivio con default 5 antes de la migracion 000057.
  static const int _umbralFacialMinimo = 50;

  /// Umbral de similitud coseno para el match facial local, en 0..1. El
  /// dashboard lo captura como porcentaje (0-100), asi que aqui se
  /// convierte; fuera de rango cae al default en vez de confiar en el valor.
  double get _umbralFacial {
    final pct = _ultimaConfig.umbralFacialPct;
    if (pct < _umbralFacialMinimo || pct > 100) {
      return KioskoConfig.defaults.umbralFacialPct / 100;
    }
    return pct / 100;
  }

  /// Debe llamarse una vez al arrancar la app (ver main.dart) antes de que
  /// cualquier flujo de registro intente usar el modo offline. Sin esto,
  /// KioskoServicio se comporta exactamente como antes (siempre en línea).
  void configurarOffline(ConnectivityService connectivity, LocalCacheDb cache) {
    _connectivity = connectivity;
    _cache = cache;
  }

  /// true cuando un error de red (DNS, socket, timeout, host inalcanzable,
  /// o corte de conexión) interrumpió la llamada.
  bool _esFalloDeRed(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TlsException) {
      return true;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('clientexception') ||
        msg.contains('network') ||
        msg.contains('connection refused') ||
        msg.contains('connection closed') ||
        msg.contains('connection reset') ||
        msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('errno') ||
        msg.contains('os error') ||
        msg.contains('handshake') ||
        msg.contains('no address associated') ||
        msg.contains('unreachable');
  }

  Future<void> _ensureLogin() async {
    if (_sessionToken != null) return;

    final token = await _storage.read(key: _keyToken);
    final kioskoIdStr = await _storage.read(key: _keyKioskoId);
    if (token == null || kioskoIdStr == null) {
      throw DeviceNotActivatedException();
    }
    _sessionToken = token;
    _kioskoId = int.parse(kioskoIdStr);
  }

  // Intenta re-autenticarse silenciosamente con la clave almacenada.
  //
  // Devuelve un resultado de tres estados, no un bool: un timeout/error de
  // red durante el intento (justo lo esperable cuando la conexión sigue
  // inestable recién vuelta de un corte) es indistinguible de "la clave ya
  // no sirve" si solo se mira true/false, y los dos llamadores de esta
  // función (obtenerConfig, _sseLoop) borraban la sesión completa
  // (cerrarSesion) ante cualquier falla -- un kiosko que perdía intenet
  // justo en el instante del re-login quedaba desactivado para siempre,
  // exigiendo reactivación manual (RFC 8628) aunque la red volviera segundos
  // después. Solo un rechazo real del servidor (login inválido) debe borrar
  // la sesión.
  Future<_ReLoginResultado> _reLogin() async {
    final claveKiosko = await _storage.read(key: _keyClave);
    if (claveKiosko == null || _kioskoId == null) {
      return _ReLoginResultado.rechazado;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/kiosko/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kiosko_id': _kioskoId, 'clave_kiosko': claveKiosko}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = body['token'] as String;
        await _storage.write(key: _keyToken, value: newToken);
        _sessionToken = newToken;
        return _ReLoginResultado.exito;
      }
      // El servidor respondió y rechazó la credencial -- esto sí es un
      // rechazo real (p.ej. el admin eliminó el kiosko), no un problema de
      // red.
      return _ReLoginResultado.rechazado;
    } catch (e) {
      return _esFalloDeRed(e)
          ? _ReLoginResultado.errorDeRed
          : _ReLoginResultado.rechazado;
    }
  }

  Future<void> guardarSesion(String token, int kioskoId, {String? claveKiosko}) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyKioskoId, value: kioskoId.toString());
    if (claveKiosko != null && claveKiosko.isNotEmpty) {
      await _storage.write(key: _keyClave, value: claveKiosko);
    }
    _sessionToken = token;
    _kioskoId = kioskoId;
  }

  Future<void> cerrarSesion() async {
    await _storage.deleteAll();
    _sessionToken = null;
    _kioskoId = null;
  }

  // ── Device Authorization Grant (RFC 8628) ──────────────────────────────────

  Future<DeviceSolicitud> solicitarCodigo() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/device/authorize'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return DeviceSolicitud.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error solicitando código (${response.statusCode})');
  }

  Future<({String token, int kioskoId, String claveKiosko})> esperarToken(String deviceCode) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/device/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_code': deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      }),
    ).timeout(const Duration(seconds: 10));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return (
        token: body['token'] as String,
        kioskoId: body['kiosko_id'] as int,
        claveKiosko: (body['clave_kiosko'] as String?) ?? '',
      );
    }
    if (response.statusCode == 428 || body['error'] == 'authorization_pending') {
      throw DeviceAuthorizationPendingException();
    }
    if (body['error'] == 'expired_token') {
      throw DeviceExpiredException();
    }
    throw Exception(body['error'] ?? 'Error (${response.statusCode})');
  }

  // ── Config & SSE ────────────────────────────────────────────────────────────

  /// Límite POR INTENTO del GET de config, no del arranque completo.
  ///
  /// Tiene que ser bastante menor que el presupuesto de arranque que aplica
  /// KioskoConfigNotifier (`presupuestoArranqueConfig`): en el
  /// camino del 401 se gastan dos intentos más el re-login, y si cada intento
  /// pudiera comerse el presupuesto entero el segundo nunca llegaría a
  /// hacerse. Con 10 pasaba justo eso.
  static const Duration timeoutConfigPorIntento = Duration(seconds: 5);

  Future<KioskoConfig> obtenerConfig() async {
    await _ensureLogin();
    var response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/mia'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(timeoutConfigPorIntento);

    if (response.statusCode == 401) {
      _sessionToken = null;
      final resultado = await _reLogin();
      if (resultado == _ReLoginResultado.exito) {
        response = await http.get(
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/mia'),
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ).timeout(timeoutConfigPorIntento);
      } else if (resultado == _ReLoginResultado.rechazado) {
        await cerrarSesion();
        throw DeviceNotActivatedException();
      } else {
        // errorDeRed: la sesión sigue siendo válida, solo no se pudo
        // renovar el token porque la red seguía caída. No hay que borrar
        // nada -- KioskoConfigNotifier.inicializar() ya cae a la config de
        // respaldo en disco ante esta excepción.
        throw Exception('re-login falló por red, sesión conservada');
      }
    }

    if (response.statusCode == 200) {
      _ultimaConfig = KioskoConfig.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      // Se respalda aparte (no solo en memoria) para el arranque en frío
      // sin internet: si el kiosko se prende ya desconectado, obtenerConfig
      // nunca llega a esta línea y KioskoConfigNotifier se queda en
      // KioskoConfig.defaults (teléfono vacío) -- sin este respaldo el
      // botón "llamar al administrador" quedaría inservible justo en el
      // caso para el que existe.
      if (_ultimaConfig.telefonoContacto.isNotEmpty) {
        await _storage.write(
            key: _keyTelefonoContacto, value: _ultimaConfig.telefonoContacto);
      }
      await _respaldarConfig(response.body);
      return _ultimaConfig;
    }
    throw Exception('Error al obtener config (${response.statusCode})');
  }

  /// Guarda el JSON crudo de la última config buena.
  ///
  /// Se respalda entera y no campo por campo (el teléfono ya tenía su propia
  /// clave, ver [_keyTelefonoContacto]) porque el problema es el mismo para
  /// todos: si el GET falla, KioskoConfigNotifier se queda en
  /// [KioskoConfig.defaults] y ahí `mensaje_bienvenida` es cadena vacía, que
  /// es justo lo que el escáner QR interpreta como "no hay pastilla que
  /// mostrar". El kiosko se veía sin nombre de fraccionamiento hasta el
  /// siguiente arranque con red.
  ///
  /// Falla en silencio: un respaldo perdido no puede tumbar el arranque.
  Future<void> _respaldarConfig(String json) async {
    try {
      await _storage.write(key: _keyConfigRespaldo, value: json);
    } catch (_) {}
  }

  /// Última config conocida en disco, o null si nunca hubo una buena (kiosko
  /// recién activado que todavía no ha logrado un solo GET).
  ///
  /// El SSE no sirve para recuperarse de esto: el backend solo emite cuando
  /// el admin guarda cambios, no manda una foto del estado al conectarse, así
  /// que un kiosko que arrancó sin red se queda con los defaults hasta que
  /// alguien toca la config en el dashboard.
  Future<KioskoConfig?> configRespaldo() async {
    try {
      final json = await _storage.read(key: _keyConfigRespaldo);
      if (json == null || json.isEmpty) return null;
      return KioskoConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Último teléfono de contacto conocido, persistido en el arranque
  /// anterior -- respaldo para cuando obtenerConfig() falla por completo
  /// (kiosko sin internet desde antes de arrancar).
  Future<String> telefonoContactoRespaldo() async {
    return await _storage.read(key: _keyTelefonoContacto) ?? '';
  }

  /// Heartbeat -- se llama en cada ciclo del chequeo de conectividad para que
  /// el dashboard admin sepa que este kiosko sigue vivo (ver UltimoPing).
  /// Falla en silencio: un ping perdido no debe interrumpir nada del flujo
  /// del kiosko, el siguiente intento en unos segundos ya lo resuelve solo.
  Future<void> ping() async {
    try {
      await _ensureLogin();
      final response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/ping'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 401) {
        _sessionToken = null;
        if (await _reLogin() == _ReLoginResultado.exito) {
          await http.post(
            Uri.parse('$_baseUrl/kioskos/$_kioskoId/ping'),
            headers: {'Authorization': 'Bearer $_sessionToken'},
          ).timeout(const Duration(seconds: 8));
        }
        // rechazado o errorDeRed: no se hace nada más aquí a propósito --
        // ping() ya falla en silencio (ver doc arriba) y el próximo ciclo de
        // 30s ya lo resuelve solo si la red vuelve; forzar cerrarSesion
        // desde aquí sería el mismo bug que en obtenerConfig/_sseLoop.
      }
    } catch (_) {}
  }

  /// El visitante tocó "llamar al vigilante" -- avisa al backend para que
  /// mande la alerta al dashboard (SSE) y a los admins del tenant (correo).
  /// Falla en silencio igual que ping(): el botón ya le mostró el teléfono
  /// al visitante para que llame directo, este aviso es un canal adicional,
  /// no el único, así que un error de red aquí no debe interrumpir nada.
  Future<void> solicitarAsistenciaUrgente() async {
    try {
      await _ensureLogin();
      final response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistencia-urgente/'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 &&
          await _reLogin() == _ReLoginResultado.exito) {
        await http.post(
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistencia-urgente/'),
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ).timeout(const Duration(seconds: 8));
      }
    } catch (_) {}
  }

  /// Reporta un intento de acceso fallido (PIN incorrecto, QR inválido) para
  /// la pestaña "Seguridad" del dashboard -- best-effort a propósito: un
  /// fallo de red al reportar no debe interrumpir ni retrasar la pantalla de
  /// error que ya está viendo el visitante/residente en el kiosko.
  ///
  /// [pathFoto] y [embedding] son opcionales: los llena
  /// EvidenciaSeguridadServicio.capturar() cuando pudo tomar la foto en
  /// segundo plano, pero un evento sin evidencia también es válido (mejor
  /// registrar el tipo y la hora sin foto que no registrar nada).
  Future<void> reportarEventoSeguridad({
    required String tipo,
    String? detalle,
    String? pathFoto,
    List<double>? embedding,
  }) async {
    Future<http.MultipartRequest> construirRequest(Uri uri) async {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_sessionToken'
        ..fields['tipo'] = tipo
        ..fields['detalle'] = detalle ?? '';
      if (embedding != null && embedding.isNotEmpty) {
        request.fields['embedding_rostro'] = jsonEncode(embedding);
      }
      if (pathFoto != null && File(pathFoto).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto', pathFoto,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      return request;
    }

    try {
      await _ensureLogin();
      final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/eventos-seguridad');
      final streamed = await (await construirRequest(uri)).send().timeout(const Duration(seconds: 8));
      if (streamed.statusCode == 401 &&
          await _reLogin() == _ReLoginResultado.exito) {
        await (await construirRequest(uri)).send().timeout(const Duration(seconds: 8));
      }
    } catch (_) {}
  }

  /// Generación del loop SSE vivo. Cada llamada a [escucharConfigStream]
  /// incrementa el contador y el loop anterior se apaga al verlo cambiado.
  ///
  /// Sin esto los loops se acumulaban: `reinicializar()` vuelve a llamar a
  /// `inicializar()`, que arranca otro loop, y el viejo es un `while (true)`
  /// sin forma de pararse -- seguía reconectando y empujando config a un
  /// notifier que a lo mejor ya nadie escucha. Uno por reactivación.
  int _sseGeneracion = 0;

  /// Cliente del loop vivo, para poder cortarle la conexión desde fuera.
  ///
  /// El contador solo se revisa entre vueltas, y un SSE sano se queda
  /// bloqueado dentro del `forEach` indefinidamente -- que es justo el caso
  /// normal. Cerrar el cliente rompe ese stream y devuelve el control al
  /// loop, que ahí sí ve que ya no es el vigente y se va.
  http.Client? _sseClient;

  /// [onRevocado] se llama si la sesión del kiosko fue revocada (ej. el admin lo
  /// eliminó desde el dashboard) y no se pudo re-autenticar: el dispositivo
  /// debe volver a la pantalla de activación.
  void escucharConfigStream(
    void Function(KioskoConfig) onConfig, {
    VoidCallback? onRevocado,
  }) {
    final generacion = ++_sseGeneracion;
    _cerrarSseVivo();
    _sseLoop(generacion, onConfig, onRevocado);
  }

  /// Apaga el loop SSE sin arrancar otro (lo llama el dispose del notifier).
  void detenerConfigStream() {
    _sseGeneracion++;
    _cerrarSseVivo();
  }

  void _cerrarSseVivo() {
    _sseClient?.close();
    _sseClient = null;
  }

  Future<void> _sseLoop(
    int generacion,
    void Function(KioskoConfig) onConfig,
    VoidCallback? onRevocado,
  ) async {
    while (generacion == _sseGeneracion) {
      try {
        await _ensureLogin();
        final client = http.Client();
        _sseClient = client;
        final request = http.Request(
          'GET',
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/config/stream'),
        )..headers['Authorization'] = 'Bearer $_sessionToken';

        final response = await client.send(request);

        if (response.statusCode == 401) {
          _sessionToken = null;
          final resultado = await _reLogin();
          if (resultado == _ReLoginResultado.rechazado) {
            await cerrarSesion();
            onRevocado?.call();
            return;
          }
          if (resultado == _ReLoginResultado.errorDeRed) {
            // La red seguía caída justo en el instante del re-login: no es
            // un rechazo del servidor, la sesión se conserva y el loop
            // reintenta como cualquier otro corte transitorio (mismo
            // manejo que el catch de abajo).
            await Future.delayed(const Duration(seconds: 5));
            continue;
          }
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        await response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
          // Un loop relevado puede tener una línea a medio camino cuando le
          // cierran el cliente: no debe entregarla, el notifier que la
          // esperaba puede estar ya desechado.
          if (generacion != _sseGeneracion) return;
          if (line.startsWith('data: ')) {
            try {
              final cuerpo = line.substring(6);
              final cfg = KioskoConfig.fromJson(
                  jsonDecode(cuerpo) as Map<String, dynamic>);
              _ultimaConfig = cfg;
              // Tambien se respalda lo que llega por aqui: si no, un cambio
              // hecho en el dashboard se perderia en el siguiente arranque
              // sin red y el kiosko volveria al mensaje viejo. Sin await: el
              // callback del stream es sincrono y _respaldarConfig ya se
              // traga sus propios errores.
              _respaldarConfig(cuerpo);
              onConfig(cfg);
            } catch (e) {
              debugPrint('SSE config parse error: $e');
            }
          }
        });
      } on DeviceNotActivatedException {
        onRevocado?.call();
        return;
      } catch (e) {
        debugPrint('SSE config stream error: $e — reconectando en 5s');
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // ── Visitas ─────────────────────────────────────────────────────────────────

  /// Registra una visita sin invitación (TipoVisitante = VISITANTE).
  ///
  /// La INE siempre es obligatoria para este tipo (ADR-0016); la foto de rostro
  /// y la placa solo se exigen si la config del kiosko las tiene encendidas. Las
  /// visitas con invitación no pasan por aquí sino por [usarInvitacion], que
  /// además consume el token y las deja aprobadas.
  Future<Map<String, dynamic>> registrarVisitante({
    required String titular,
    required String curp,
    required String casaDestino,
    String placa = '',
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
    double? nitidezIneScore,
    String? calidadIne,
    List<double>? embeddingRostro,
    String? motivo,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _encolarVisitante(
        cache: cache,
        titular: titular,
        curp: curp,
        casaDestino: casaDestino,
        placa: placa,
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        pathFotoPlaca: pathFotoPlaca,
        embeddingRostro: embeddingRostro,
        motivo: motivo,
      );
    }

    try {
      await _ensureLogin();
      return await _enviarRegistro(
        titular: titular,
        curp: curp,
        casaDestino: casaDestino,
        placa: placa,
        tipoVisitante: 'VISITANTE',
        pathFotoIne: pathFotoIne,
        pathFotoRostro: pathFotoRostro,
        pathFotoPlaca: pathFotoPlaca,
        reintento: false,
        clientId: clientId,
        nitidezIneScore: nitidezIneScore,
        calidadIne: calidadIne,
        embeddingRostro: embeddingRostro,
        motivo: motivo,
      );
    } catch (e) {
      // La red parecía disponible pero la llamada falló a medio camino — si
      // fue un fallo de red real (no un rechazo legítimo del servidor), no
      // se pierde el registro: se encola igual que si hubiéramos detectado
      // el corte de antemano.
      if (cache != null && _esFalloDeRed(e)) {
        return _encolarVisitante(
          cache: cache,
          titular: titular,
          curp: curp,
          casaDestino: casaDestino,
          placa: placa,
          pathFotoIne: pathFotoIne,
          pathFotoRostro: pathFotoRostro,
          pathFotoPlaca: pathFotoPlaca,
          embeddingRostro: embeddingRostro,
          motivo: motivo,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _encolarVisitante({
    required LocalCacheDb cache,
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    List<double>? embeddingRostro,
    String? motivo,
  }) async {
    final clientId = _uuid.v4();
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'visitante_nuevo',
      payload: {
        'titular': titular,
        'curp': curp,
        'casa_destino': casaDestino,
        'motivo': motivo ?? '',
        'placa': placa,
        // Va en el payload y no en fotoPaths: es un vector, no un archivo.
        // Sin esto, una visita encolada offline perdia el identificador al
        // drenarse y volvia a contar como primera visita.
        if (embeddingRostro != null && embeddingRostro.isNotEmpty)
          'embedding_rostro': embeddingRostro,
      },
      fotoPaths: {
        'ine': ?pathFotoIne,
        'rostro': ?pathFotoRostro,
        'placa': ?pathFotoPlaca,
      },
    );
    // Respuesta sintetizada localmente — misma forma que ya arma
    // _enviarRegistro para RegisterVisita: la UI (resumen_solicitud_view)
    // no distingue "encolado" de "enviado".
    return {
      'id': null,
      'estado': 'PENDIENTE',
      'client_id': clientId,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Valida un token de invitación sin consumirlo. El kiosko lo usa al escanear
  /// el QR para saber a nombre de quién y a qué casa va la visita antes de pedir
  /// las capturas que exija su configuración.
  Future<Map<String, dynamic>> validarInvitacion(String token) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      final inv = await cache.obtenerInvitacionPorToken(token);
      if (inv != null) return inv;
      throw Exception('Invitación no válida, expirada o no encontrada');
    }

    try {
      await _ensureLogin();
      final response = await http.get(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/invitaciones/validar?token=$token'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 404) {
        throw Exception('Invitación no válida, expirada o agotada');
      }
      if (cache != null) {
        final inv = await cache.obtenerInvitacionPorToken(token);
        if (inv != null) return inv;
      }
      throw Exception('Error al validar invitación (${response.statusCode})');
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        final inv = await cache.obtenerInvitacionPorToken(token);
        if (inv != null) return inv;
      }
      rethrow;
    }
  }

  /// Consume la invitación y registra la visita como APROBADA.
  ///
  /// Las capturas van en el mismo request: el backend valida contra la config
  /// del kiosko y crea una sola visita. Sin capturas se manda un POST vacío,
  /// que es el caso del kiosko peatonal sin toggles de invitado.
  Future<Map<String, dynamic>> usarInvitacion(
    String token, {
    String placa = '',
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
    double? nitidezIneScore,
    String? calidadIne,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _usarInvitacionOffline(
        cache, token,
        placa: placa, curp: curp,
        pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
      );
    }

    try {
      return await _usarInvitacionRemota(
        token,
        placa: placa, curp: curp,
        pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
        clientId: clientId,
        nitidezIneScore: nitidezIneScore,
        calidadIne: calidadIne,
      );
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _usarInvitacionOffline(
          cache, token,
          placa: placa, curp: curp,
          pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _usarInvitacionRemota(
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    String? clientId,
    double? nitidezIneScore,
    String? calidadIne,
  }) async {
    await _ensureLogin();
    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/invitaciones/$token/usar');

    // Con client_id (reproduciendo un registro offline) siempre se manda
    // multipart aunque no haya capturas: el backend solo lee client_id del
    // form-data, no de un POST sin cuerpo.
    final sinCapturas = clientId == null &&
        placa.isEmpty &&
        curp == null &&
        pathFotoIne == null &&
        pathFotoRostro == null &&
        pathFotoPlaca == null;

    final http.Response response;
    if (sinCapturas) {
      response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 10));
    } else {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $_sessionToken'
        ..fields['placa'] = placa
        ..fields['curp'] = curp ?? ''
        ..fields['client_id'] = clientId ?? '';

      if (nitidezIneScore != null) {
        request.fields['nitidez_ine_score'] = nitidezIneScore.toString();
      }
      if (calidadIne != null) {
        request.fields['calidad_ine'] = calidadIne;
      }

      for (final foto in [
        ('foto_documento', pathFotoIne),
        ('foto_rostro', pathFotoRostro),
        ('foto_placa', pathFotoPlaca),
      ]) {
        if (foto.$2 == null || !File(foto.$2!).existsSync()) continue;
        request.files.add(
          await http.MultipartFile.fromPath(
            foto.$1, foto.$2!,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) {
      throw InvitacionInvalidaException();
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error al procesar invitación (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _usarInvitacionOffline(
    LocalCacheDb cache,
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
  }) async {
    final invitacionLocal = await cache.obtenerInvitacionPorToken(token);
    if (invitacionLocal == null) {
      throw InvitacionInvalidaException();
    }

    final clientId = _uuid.v4();
    await cache.marcarInvitacionConsumidaLocal(token);
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'invitacion',
      payload: {
        'token': token,
        'placa': placa,
        'curp': curp,
        'titular': invitacionLocal['titular'],
        'casa_destino': invitacionLocal['casa_destino'],
      },
      fotoPaths: {
        'ine': ?pathFotoIne,
        'rostro': ?pathFotoRostro,
        'placa': ?pathFotoPlaca,
      },
    );
    return {
      'titular': invitacionLocal['titular'],
      'casa_destino': invitacionLocal['casa_destino'],
      'visita_id': null,
      'estado': 'APROBADO',
      'placa': placa,
    };
  }

  /// Verifica el QR personal de una Persona (app Kigo): valida su firma y,
  /// en la misma llamada, resuelve si es miembro/invitado/desconocido en
  /// este centro. Si es invitado, el backend ya deja registrada la visita
  /// APROBADA — no hace falta una llamada aparte para consumirla.
  Future<Map<String, dynamic>> verificarQrPersona(int personaId, String firma) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _verificarQrPersonaOffline(cache, personaId, firma);
    }

    try {
      await _ensureLogin();
      final response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/personas/verificar-qr'),
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'persona_id': personaId, 'firma': firma}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw Exception('Código QR inválido');
      }
      if (response.statusCode == 404) {
        throw Exception('No se encontró esa cuenta de Kigo');
      }
      if (cache != null) {
        return _verificarQrPersonaOffline(cache, personaId, firma);
      }
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error al verificar el QR (${response.statusCode})');
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _verificarQrPersonaOffline(cache, personaId, firma);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verificarQrPersonaOffline(
    LocalCacheDb cache,
    int personaId,
    String firma,
  ) async {
    if (!QrFirmaVerificador.verificar(personaId, firma)) {
      throw Exception('Código QR inválido');
    }

    final residentes = await cache.obtenerResidentes();
    final residenteMatch = residentes.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['persona_id'] == personaId,
      orElse: () => null,
    );
    final invitacionMatch = residenteMatch == null
        ? await cache.obtenerInvitacionActivaPorPersonaId(personaId)
        : null;

    final resolucion = resolverQrOffline(
      residenteMatch: residenteMatch,
      invitacionMatch: invitacionMatch,
    );

    switch (resolucion.estado) {
      case EstadoQrOffline.miembro:
        return {
          'estado': 'miembro',
          'tipo': 'RESIDENTE',
          'nombre': resolucion.nombre,
          'casa_destino': resolucion.casaDestino,
        };
      case EstadoQrOffline.invitado:
        final clientId = _uuid.v4();
        await cache.encolarVisita(
          clientId: clientId,
          tipo: 'qr_persona',
          payload: {
            'persona_id': personaId,
            'firma': firma,
            'nombre': resolucion.nombre,
            'casa_destino': resolucion.casaDestino,
          },
          fotoPaths: const {},
        );
        return {
          'estado': 'invitado',
          'nombre': resolucion.nombre,
          'casa_destino': resolucion.casaDestino,
        };
      case EstadoQrOffline.ninguno:
        throw Exception('Sin membresía ni invitación en este centro');
    }
  }

  Future<Map<String, dynamic>> validarPinResidente(String pin, {int? personaId, String? clientId}) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _validarPinOffline(cache, pin, personaId: personaId, clientId: clientId);
    }

    try {
      return await _validarPinRemoto(pin, personaId: personaId, clientId: clientId);
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _validarPinOffline(cache, pin, personaId: personaId, clientId: clientId);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _validarPinRemoto(String pin, {int? personaId, String? clientId}) async {
    await _ensureLogin();
    final bodyMap = <String, dynamic>{'pin': pin};
    if (personaId != null) bodyMap['persona_id'] = personaId;
    if (clientId != null) bodyMap['client_id'] = clientId;

    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/login'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyMap),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('PIN incorrecto');
    }
    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error al validar PIN (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _validarPinOffline(
    LocalCacheDb cache,
    String pin, {
    int? personaId,
    String? clientId,
  }) async {
    final residentes = await cache.obtenerResidentes();
    final matches = <Map<String, dynamic>>[];
    for (final r in residentes) {
      final pinHash = r['pin_hash'] as String?;
      if (pinHash != null && pinHash.isNotEmpty) {
        try {
          if (BCrypt.checkpw(pin, pinHash)) {
            matches.add(r);
          }
        } catch (_) {}
      }
    }
    if (matches.isEmpty) {
      throw Exception('PIN incorrecto');
    }
    if (matches.length > 1 && personaId == null) {
      return {
        'requiere_seleccion': true,
        'candidatos': matches.map((m) => {
          'persona_id': m['persona_id'],
          'nombre': '${m['nombre']} ${m['apellido_paterno']}',
          'casa_destino': m['casa_destino'],
        }).toList(),
      };
    }
    final match = personaId != null
        ? matches.firstWhere((m) => m['persona_id'] == personaId, orElse: () => matches.first)
        : matches.first;

    final cid = clientId ?? _uuid.v4();
    final nombreCompleto = '${match['nombre']} ${match['apellido_paterno']}';
    await cache.encolarVisita(
      clientId: cid,
      tipo: 'pin_residente',
      payload: {
        'pin': pin,
        'persona_id': match['persona_id'],
        'nombre': nombreCompleto,
        'casa_destino': match['casa_destino'],
      },
      fotoPaths: const {},
    );
    return {
      'nombre': nombreCompleto,
      'casa_destino': match['casa_destino'],
      'es_invitado_frecuente': match['es_invitado_frecuente'] ?? false,
    };
  }

  Future<Map<String, dynamic>> verificarRostroResidente(
    List<double> embedding, {
    String? clientId,
  }) async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      return _verificarRostroOffline(cache, embedding);
    }

    try {
      return await _verificarRostroRemoto(embedding, clientId: clientId);
    } catch (e) {
      if (cache != null && _esFalloDeRed(e)) {
        return _verificarRostroOffline(cache, embedding);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _verificarRostroRemoto(
    List<double> embedding, {
    String? clientId,
  }) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/residentes/verificar-rostro'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'embedding': embedding, 'client_id': clientId ?? ''}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw Exception('Rostro no reconocido');
    }
    throw Exception('Error al verificar rostro (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _verificarRostroOffline(
    LocalCacheDb cache,
    List<double> embedding,
  ) async {
    final residentes = await cache.obtenerResidentes();
    final match = mejorCoincidenciaLocal(residentes, embedding, umbral: _umbralFacial);
    if (match == null) {
      throw Exception('Rostro no reconocido');
    }
    final clientId = _uuid.v4();
    final nombreCompleto = '${match['nombre']} ${match['apellido_paterno']}';
    await cache.encolarVisita(
      clientId: clientId,
      tipo: 'rostro_residente',
      payload: {
        'embedding': embedding,
        'nombre': nombreCompleto,
        'casa_destino': match['casa_destino'],
      },
      fotoPaths: const {},
    );
    return {
      'nombre': nombreCompleto,
      'casa_destino': match['casa_destino'],
      'es_invitado_frecuente': match['es_invitado_frecuente'] ?? false,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerDestinos() async {
    final connectivity = _connectivity;
    final cache = _cache;
    if (connectivity != null && cache != null && connectivity.isOffline) {
      final destinosLocales = await cache.obtenerDestinos();
      if (destinosLocales.isNotEmpty) return destinosLocales;
    }

    try {
      await _ensureLogin();
      var response = await http.get(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/destinos/'),
        headers: {'Authorization': 'Bearer $_sessionToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 401) {
        _sessionToken = null;
        if (await _reLogin() == _ReLoginResultado.exito) {
          response = await http.get(
            Uri.parse('$_baseUrl/kioskos/$_kioskoId/destinos/'),
            headers: {'Authorization': 'Bearer $_sessionToken'},
          ).timeout(const Duration(seconds: 5));
        }
      }

      if (response.statusCode == 200) {
        final list = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
        if (cache != null && list.isNotEmpty) {
          cache.reemplazarDestinos(list).ignore();
        }
        return list;
      }
      if (cache != null) {
        final destinosLocales = await cache.obtenerDestinos();
        if (destinosLocales.isNotEmpty) return destinosLocales;
      }
      throw Exception('Error al obtener destinos (${response.statusCode})');
    } catch (e) {
      if (cache != null) {
        final destinosLocales = await cache.obtenerDestinos();
        if (destinosLocales.isNotEmpty) return destinosLocales;
      }
      rethrow;
    }
  }

  Future<String> preguntarAsistente(String pregunta) async {
    try {
      await _ensureLogin();
      var response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistente/preguntar'),
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'pregunta': pregunta}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 401) {
        _sessionToken = null;
        if (await _reLogin() == _ReLoginResultado.exito) {
          response = await http.post(
            Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistente/preguntar'),
            headers: {
              'Authorization': 'Bearer $_sessionToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'pregunta': pregunta}),
          ).timeout(const Duration(seconds: 25));
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['respuesta'] as String? ?? '';
      }
      return 'No puedo responder eso ahora mismo.';
    } catch (_) {
      return 'No puedo responder eso ahora mismo.';
    }
  }

  Future<CampoExtraido> extraerCampoAsistente(String transcripcion, String tipoCampo) async {
    try {
      await _ensureLogin();
      var response = await http.post(
        Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistente/extraer-campo'),
        headers: {
          'Authorization': 'Bearer $_sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'transcripcion': transcripcion, 'tipo_campo': tipoCampo}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 401) {
        _sessionToken = null;
        if (await _reLogin() == _ReLoginResultado.exito) {
          response = await http.post(
            Uri.parse('$_baseUrl/kioskos/$_kioskoId/asistente/extraer-campo'),
            headers: {
              'Authorization': 'Bearer $_sessionToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'transcripcion': transcripcion, 'tipo_campo': tipoCampo}),
          ).timeout(const Duration(seconds: 25));
        }
      }

      if (response.statusCode == 200) {
        return CampoExtraido.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return CampoExtraido(confianza: 0);
    } catch (_) {
      return CampoExtraido(confianza: 0);
    }
  }

  // ── Reproducción de la cola offline (solo para SyncWorker) ─────────────────
  //
  // A diferencia de registrarVisitante/usarInvitacion/verificarRostroResidente,
  // estos métodos NO reencolan ante un fallo de red: si lo hicieran, un corte
  // a medio-drenado se tragaría el error silenciosamente y crearía un
  // duplicado en la cola en vez de dejar que SyncWorker detenga el drenado y
  // reintente el mismo client_id en el siguiente ciclo.

  Future<Map<String, dynamic>> reproducirVisitanteNuevo({
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required String clientId,
    List<double>? embeddingRostro,
    String? motivo,
  }) async {
    await _ensureLogin();
    return _enviarRegistro(
      titular: titular,
      curp: curp,
      casaDestino: casaDestino,
      placa: placa,
      tipoVisitante: 'VISITANTE',
      pathFotoIne: pathFotoIne,
      pathFotoRostro: pathFotoRostro,
      pathFotoPlaca: pathFotoPlaca,
      reintento: false,
      clientId: clientId,
      embeddingRostro: embeddingRostro,
      motivo: motivo,
    );
  }

  Future<Map<String, dynamic>> reproducirInvitacion(
    String token, {
    required String placa,
    String? curp,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required String clientId,
  }) {
    return _usarInvitacionRemota(
      token,
      placa: placa, curp: curp,
      pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro, pathFotoPlaca: pathFotoPlaca,
      clientId: clientId,
    );
  }

  Future<Map<String, dynamic>> reproducirVerificacionRostro(
    List<double> embedding, {
    required String clientId,
  }) {
    return _verificarRostroRemoto(embedding, clientId: clientId);
  }

  Future<Map<String, dynamic>> reproducirPinResidente(
    String pin, {
    int? personaId,
    required String clientId,
  }) {
    return _validarPinRemoto(pin, personaId: personaId, clientId: clientId);
  }

  Future<Map<String, dynamic>> reproducirQrPersona(
    int personaId, {
    required String firma,
    required String clientId,
  }) {
    return _verificarQrPersonaRemoto(personaId, firma: firma, clientId: clientId);
  }

  Future<Map<String, dynamic>> _verificarQrPersonaRemoto(
    int personaId, {
    required String firma,
    String? clientId,
  }) async {
    await _ensureLogin();
    final response = await http.post(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/personas/verificar-qr'),
      headers: {
        'Authorization': 'Bearer $_sessionToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'persona_id': personaId, 'firma': firma, 'client_id': clientId ?? ''}),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al verificar QR (${response.statusCode})');
  }

  Future<Map<String, dynamic>> obtenerSnapshot() async {
    await _ensureLogin();
    var response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/sync/snapshot'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      _sessionToken = null;
      if (await _reLogin() == _ReLoginResultado.exito) {
        response = await http.get(
          Uri.parse('$_baseUrl/kioskos/$_kioskoId/sync/snapshot'),
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ).timeout(const Duration(seconds: 15));
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener snapshot (${response.statusCode})');
  }

  Future<Map<String, dynamic>> obtenerEstadoVisita(int visitaId) async {
    await _ensureLogin();
    final response = await http.get(
      Uri.parse('$_baseUrl/kioskos/$_kioskoId/visitas/$visitaId'),
      headers: {'Authorization': 'Bearer $_sessionToken'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al consultar estado de visita (${response.statusCode})');
  }

  Future<Map<String, dynamic>> _enviarRegistro({
    required String titular,
    required String curp,
    required String casaDestino,
    required String placa,
    required String tipoVisitante,
    String? pathFotoIne,
    String? pathFotoRostro,
    String? pathFotoPlaca,
    required bool reintento,
    String? clientId,
    double? nitidezIneScore,
    String? calidadIne,
    List<double>? embeddingRostro,
    String? motivo,
  }) async {
    final uri = Uri.parse('$_baseUrl/kioskos/$_kioskoId/visitas/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_sessionToken'
      ..fields['titular'] = titular
      ..fields['tipo_visitante'] = tipoVisitante
      ..fields['curp'] = curp
      ..fields['casa_destino'] = casaDestino
      ..fields['motivo'] = motivo ?? ''
      ..fields['placa'] = placa
      ..fields['client_id'] = clientId ?? '';

    if (nitidezIneScore != null) {
      request.fields['nitidez_ine_score'] = nitidezIneScore.toString();
    }
    if (calidadIne != null) {
      request.fields['calidad_ine'] = calidadIne;
    }

    // Solo se declara explícitamente cuando sí hay INE -- para el resto de
    // los casos (placa capturada, o reconocido solo por rostro en un
    // kiosko peatonal donde nunca hay placa) el backend ya decide el
    // fallback correcto (ROSTRO > PLACA > SIN_DOCUMENTO) a partir de lo que
    // realmente se envió, sin que el kiosko tenga que adivinarlo.
    if (pathFotoIne != null) {
      request.fields['tipo_documento'] = 'INE';
    }

    // La huella facial, no la foto: es lo que permite reconocer a este
    // visitante en su siguiente entrada cuando no hay INE ni placa que lo
    // identifiquen. La foto ya viaja aparte como evidencia.
    if (embeddingRostro != null && embeddingRostro.isNotEmpty) {
      request.fields['embedding_rostro'] = jsonEncode(embeddingRostro);
    }

    if (pathFotoIne != null && File(pathFotoIne).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_documento', pathFotoIne,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (pathFotoRostro != null && File(pathFotoRostro).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_rostro', pathFotoRostro,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (pathFotoPlaca != null && File(pathFotoPlaca).existsSync()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'foto_placa', pathFotoPlaca,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401 && !reintento) {
      _sessionToken = null;
      final resultado = await _reLogin();
      if (resultado == _ReLoginResultado.exito) {
        return _enviarRegistro(
          titular: titular, curp: curp,
          casaDestino: casaDestino, placa: placa,
          tipoVisitante: tipoVisitante,
          pathFotoIne: pathFotoIne, pathFotoRostro: pathFotoRostro,
          pathFotoPlaca: pathFotoPlaca,
          reintento: true,
          clientId: clientId,
        );
      }
      if (resultado == _ReLoginResultado.errorDeRed) {
        // Sesión conservada -- solo fue un corte de red durante el
        // re-login, no un rechazo del servidor. SyncWorker reintentará este
        // mismo client_id en el siguiente ciclo (ver comentario de la
        // sección de arriba: estos métodos no reencolan solos).
        throw Exception('re-login falló por red, sesión conservada');
      }
      await cerrarSesion();
      throw DeviceNotActivatedException();
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Error ${response.statusCode}');
  }
}
