import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/marca_badge.dart';
import 'package:kigo_kiosco/core/widgets/marco_guia_camara.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kigo_kiosco/core/services/led_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/face_detector_servicio.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/residente/services/camera_image_convertidor.dart';
import 'package:kigo_kiosco/features/residente/services/reconocimiento_facial_servicio.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_pin_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/resident_welcome_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_pin_view.dart';
import 'package:kigo_kiosco/features/welcome/views/resident_welcome_view.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// El header de esta pantalla crece 10px, igual que el de la bienvenida: el
/// botón de regresar de 44 a 54, el isotipo de 48 a 58 y la mascota del
/// asistente de 96 a 106.
///
/// Lo de adentro de cada pieza NO suma 10: sigue la proporción de su caja.
/// Sumarle 10 a la flecha la dejaría llenando el botón de borde a borde, y 10
/// más al subtítulo lo pondría casi tan grande como el nombre.
///
/// Son los mismos números que en `welcome_view.dart`, escritos aparte: las
/// dos pantallas dibujan su header a mano y no comparten widget. Si se toca
/// uno hay que tocar el otro (o extraer el header a un widget común).
const double _ladoBotonRegresar = 54;
const double _escalaBotonRegresar = _ladoBotonRegresar / 44;
const double _tamanoFlechaRegresar = 18 * _escalaBotonRegresar;
const double _radioBotonRegresar = 12 * _escalaBotonRegresar;

/// Isotipo, nombre y subtítulo crecen con un solo factor -- el del isotipo,
/// que es lo único de los tres con una medida en px que se pueda subir 10.
const double _ladoLogoHeader = 58;
const double _escalaLockup = _ladoLogoHeader / 48;
const double _huecoLogoNombre = 14 * _escalaLockup;
const double _fuenteNombreHeader = 29 * _escalaLockup;
const double _fuenteSubtituloHeader = 14 * _escalaLockup;
const double _huecoNombreSubtitulo = 2 * _escalaLockup;
const double _espaciadoSubtituloHeader = 4 * _escalaLockup;

/// La mascota de esta pantalla, 10 más que la de las demás
/// ([KigoDesign.ladoAsistente]). Va por parámetro y no subiendo la constante
/// para no descuadrar a las otras pantallas que se anclan a ella.
const double _ladoAsistenteHeader = KigoDesign.ladoAsistente + 10;

/// Los 10px de más son sólo para los lienzos que los tienen.
///
/// La mascota cuelga del techo y debajo de ella arranca "Mira a la cámara
/// para identificarte". En un panel o una tablet sobra sitio (69px de aire en
/// el de 800x1280, 3 en el más apretado); en un teléfono el área facial --
/// que se dimensiona contra el ancho -- sube el texto, y ahí la mascota ya
/// rozaba la instrucción con sus 96 de siempre: medido, 0.9px de aire. Diez
/// más se le metían 8px encima. Por debajo de una tablet se queda como
/// estaba: crecer no vale que se encime.
double _ladoAsistente(double anchoPantalla) =>
    anchoPantalla >= 600 ? _ladoAsistenteHeader : KigoDesign.ladoAsistente;

/// El botón de "acceder por PIN" crece 20px de alto: medía 48 con la fuente
/// real (12 de padding arriba y abajo, 1.5 de borde y 21 de renglón) y pasa a
/// 68. Multiplica TODO lo de adentro -- padding, borde, radio, icono,
/// separación y letra -- para que sea el mismo botón más grande y no una caja
/// más alta con el contenido nadando dentro.
const double _escalaBotonPin = 68 / 48;

/// Mínimo del óvalo de la cámara. Por debajo deja de leerse como un encuadre
/// de rostro.
const double _altoMinimoOvalo = 160.0;

/// Lo que ocupa la columna sin contar el óvalo -- header, instrucción,
/// pastilla de estado, botón de PIN, sus separaciones y los paddings de
/// PantallaAdaptable, con la reserva de los botones flotantes incluida.
/// Medido con tester.getRect.
///
/// Eran 500 cuando el header medía 63 de alto y el botón de PIN 48. Los dos
/// crecieron (54 el botón de regresar, 58 el isotipo, 68 el de PIN) y el tope
/// se quedó corto: en un lienzo de 800x800 el botón terminaba 27px dentro de
/// la franja reservada abajo. En el panel de 800x1280 este término no manda
/// -- ahí al óvalo lo limita el 50% del alto -- así que subirlo no cambia
/// nada de lo que se ve en el kiosko.
const double _altoFijoColumna = 530.0;

/// Los 20px de más del botón de PIN son sólo para los lienzos que los tienen.
///
/// El óvalo es la única pieza elástica de la columna: cede alto hasta
/// [_altoMinimoOvalo] para que quepa todo lo demás. Cuando ya está en ese
/// mínimo no hay de dónde sacar los 20 -- la columna se desborda hacia abajo
/// y el botón se mete en los botones flotantes (medido en 320x640: 30px
/// encima). Ahí se queda como estaba.
double _escalaPin(BuildContext context) {
  final altoUtil = MediaQuery.sizeOf(context).height -
      MediaQuery.paddingOf(context).vertical;
  return altoUtil - _altoFijoColumna >= _altoMinimoOvalo
      ? _escalaBotonPin
      : 1.0;
}

/// Padding horizontal de la pantalla, que es también el `rightDelBorde` de la
/// mascota: por eso la mascota arranca justo en el borde derecho del header.
const double _margenHorizontal = 34;

/// Aire mínimo entre el lockup de marca y la mascota que flota a su derecha.
const double _aireLockupMascota = 12;

class ResidenteAccesoView extends StatefulWidget {
  const ResidenteAccesoView({super.key});

  @override
  State<ResidenteAccesoView> createState() => _ResidenteAccesoViewState();
}

class _ResidenteAccesoViewState extends State<ResidenteAccesoView>
    with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage();
  static const _keyConsentTs = 'cara_consent_ts';

  bool _consentDado = false;
  bool _verificandoConsent = true;

  CameraController? _cameraController;
  bool _camaraInicializando = false;
  String? _camaraError;

  final _led = LedServicio();
  final _reconocimientoServicio = ReconocimientoFacialServicio();

  /// Chequeo liviano (solo ML Kit, sin TFLite ni red) para el sondeo de cada
  /// frame. Antes cada tick del sondeo corría el embedding completo (TFLite)
  /// Y una ida y vuelta al backend, y encima se exigían 2 coincidencias
  /// CONFIRMADAS POR EL BACKEND seguidas -- eso pagaba el costo caro (cámara
  /// + ML Kit accurate + TFLite + red, potencialmente 10s de timeout por
  /// intento) dos veces por cada acceso. Ahora el costo caro se paga una
  /// sola vez, cuando ya hay un frame estable.
  ///
  /// El sondeo en sí YA NO toma una foto fija por intento
  /// (`controller.takePicture()`): eso dispara el pipeline completo de
  /// captura fija del hardware (enfoque, JPEG, escritura a disco) en cada
  /// ciclo, y en el HAL de este panel (ya documentado como frágil en
  /// AjustesCamara) eso pausaba brevemente la vista previa -- el "se
  /// congela la pantalla por momentos" reportado. Ahora se lee el stream de
  /// la vista previa en vivo (`startImageStream`), mucho más barato; la
  /// foto fija de verdad solo se toma UNA vez, cuando ya se confirmó un
  /// frame estable y toca calcular el embedding real.
  final _detectorLigero = FaceDetectorServicio();
  static const _deteccionesRequeridas = 2;
  int _deteccionesConsecutivas = 0;
  bool _procesandoFrame = false;
  bool _streamActivo = false;

  // Controla el bucle de reintentos.
  bool _bucleVerificacionActivo = false;

  /// Se enciende apenas se confirma la racha de 2 coincidencias -- da la
  /// misma pausa visual (aro verde + check) que ya tiene el registro de
  /// visitante antes de navegar, en vez de saltar a la siguiente pantalla
  /// sin ningún feedback de "ya te reconocí".
  bool _coincidenciaConfirmada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verificarConsent();
  }

  // El kiosko corre 24/7 y Android le quita la cámara cada vez que algo pasa a
  // primer plano (MDM, protector de pantalla). Sin esto la vista previa vuelve
  // congelada para siempre: hay que soltar el controlador y volver a abrirlo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _bucleVerificacionActivo = false;
      _streamActivo = false;
      _led.apagar();
      _cameraController = null;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _consentDado) {
      _iniciarCamara();
    }
  }

  Future<void> _verificarConsent() async {
    final ts = await _storage.read(key: _keyConsentTs);
    if (mounted) {
      setState(() {
        _consentDado = ts != null;
        _verificandoConsent = false;
      });
      if (_consentDado) {
        _iniciarCamara();
      } else {
        _pedirConsent();
      }
    }
  }

  Future<void> _pedirConsent() async {
    final aceptado = await _mostrarConsentimientoFacial(context);
    if (!mounted) return;
    if (aceptado) {
      await _storage.write(
        key: _keyConsentTs,
        value: DateTime.now().toIso8601String(),
      );
      setState(() => _consentDado = true);
      _iniciarCamara();
    } else {
      Navigator.of(context).pop();
    }
  }

  // Activa la cámara frontal para mostrar la vista en vivo dentro del círculo
  Future<void> _iniciarCamara() async {
    if (_cameraController != null || _camaraInicializando) return;
    setState(() {
      _camaraInicializando = true;
      _camaraError = null;
    });

    try {
      final camara = await CamaraKiosko.paraRostro();
      final controller = CamaraKiosko.controlador(
        camara,
        AjustesCamara.resolucionRostro,
        // NV21 (un solo plano) es lo único que este flujo sabe convertir a
        // InputImage para el sondeo en vivo -- ver camera_image_convertidor.dart.
        formatoImagen: ImageFormatGroup.nv21,
      );

      await CamaraKiosko.inicializar(controller);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _camaraInicializando = false;
      });

      _led.encenderIluminacion();

      _bucleVerificacionActivo = true;
      await _iniciarStream();
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      if (mounted) {
        setState(() {
          _camaraInicializando = false;
          _camaraError = AppLocalizations.t(
            context,
            'no_se_pudo_activar_camara',
          );
        });
      }
    }
  }

  // Arranca (o reanuda) la lectura de la vista previa en vivo -- el sondeo
  // "gratis" que reemplaza al takePicture() por tick.
  Future<void> _iniciarStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _streamActivo) return;
    _streamActivo = true;
    await controller.startImageStream(_onFrame);
  }

  // Sondeo de cada frame de la vista previa: solo el chequeo liviano (ML
  // Kit, sin TFLite ni red). El embedding + la verificación contra el
  // backend se pagan una sola vez, en _confirmarConFotoReal, cuando ya hubo
  // 2 frames consecutivos válidos.
  Future<void> _onFrame(CameraImage frame) async {
    if (!_bucleVerificacionActivo || _procesandoFrame) return;

    final inputImage = convertirFrameAInputImage(frame);
    if (inputImage == null) return;

    _procesandoFrame = true;
    try {
      final esValido = await _detectorLigero.tieneRostroValidoEnFrame(inputImage);

      if (!esValido) {
        _deteccionesConsecutivas = 0;
        return;
      }

      _deteccionesConsecutivas++;
      if (_deteccionesConsecutivas < _deteccionesRequeridas) return;
      _deteccionesConsecutivas = 0;

      await _confirmarConFotoReal();
    } catch (e) {
      _deteccionesConsecutivas = 0;
    } finally {
      _procesandoFrame = false;
    }
  }

  // Frame estable confirmado (2 detecciones seguidas del chequeo liviano) --
  // ahora sí vale la pena pagar el costo real: una foto fija de verdad
  // (para el embedding, que necesita la mejor calidad posible) + TFLite +
  // una sola ida y vuelta al backend para comparar contra los residentes.
  //
  // takePicture() no se puede llamar con el stream activo -- hay que
  // pararlo primero y, si no hubo match, reanudarlo para seguir buscando.
  Future<void> _confirmarConFotoReal() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.stopImageStream();
    } catch (_) {}
    _streamActivo = false;

    XFile? foto;
    try {
      foto = await controller.takePicture();
      await _confirmarYVerificar(foto.path);
    } catch (e) {
      // Sin match, sin red, rostro no reconocido, etc. -- se reanuda el
      // sondeo abajo en el finally, en vez de dejar la pantalla congelada.
    } finally {
      if (foto != null) {
        unawaited(
          Future(() async {
            try {
              await File(foto!.path).delete();
            } catch (_) {}
          }),
        );
      }
      // Si _confirmarYVerificar tuvo éxito, ya apagó _bucleVerificacionActivo.
      if (_bucleVerificacionActivo && mounted) {
        await _iniciarStream();
      }
    }
  }

  // Calcula el embedding de la foto fija ya tomada y lo manda al backend a
  // comparar contra los residentes -- llamado desde _confirmarConFotoReal.
  Future<void> _confirmarYVerificar(String pathFoto) async {
    final embedding = await _reconocimientoServicio.calcularEmbedding(pathFoto);
    if (embedding == null) return;

    final resultado = await KioskoServicio().verificarRostroResidente(embedding);
    final nombre = resultado['nombre'] as String?;
    final casaDestino = resultado['casa_destino'] as String?;
    final esInvitadoFrecuente = resultado['es_invitado_frecuente'] == true;

    if (!mounted) return;
    _bucleVerificacionActivo = false;
    _led.apagar();
    setState(() => _coincidenciaConfirmada = true);

    // Misma pausa breve que el registro de visitante (scanner_rostro_widget)
    // para que el aro verde + check se alcance a ver antes de navegar.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResidentWelcomeView(
            viewModel: ResidentWelcomeViewModel(
              nombre: nombre ?? AppLocalizations.t(context, 'residente_label'),
              casaDestino: casaDestino ?? '',
              esInvitadoFrecuente: esInvitadoFrecuente,
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bucleVerificacionActivo = false;
    _streamActivo = false;
    _led.apagar();
    unawaited(_reconocimientoServicio.dispose());
    _detectorLigero.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _irAlPin() {
    _led.apagar();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentPinView(viewModel: ResidentPinViewModel()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoConsent) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(
          child: CircularProgressIndicator(
            color: KigoDesign.brand,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          body: PantallaAdaptable(
            // Pantalla fija: aquí no hay nada que leer más abajo, el residente
            // solo tiene que ponerse frente a la cámara. Arrastrarla solo
            // descuadraba la vista contra la mascota y los botones flotantes,
            // que van en el Stack y no se mueven con el contenido.
            desplazable: false,
            // Ver welcome_view.dart: el footer queda detrás del
            // micrófono/vigilante sin esta reserva extra abajo.
            padding: const EdgeInsets.fromLTRB(34, 48, 34, 48 + KigoDesign.clearanceBotonesFlotantes),
            child: Column(
              children: [
                _buildHeader(context),
                const Spacer(),
                _buildAreaFacial(),
                const SizedBox(height: 40),
                _buildPinFallback(),
                const Spacer(),
              ],
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // A la altura del logotipo, DENTRO de la franja del header, no
          // debajo: con topDelBorde: 48 el bloque (etiqueta + mascota, 97 de
          // alto) llegaba hasta y≈145 y se montaba sobre "Mira a la cámara
          // para identificarte", que arranca justo después del header.
          //
          // 2 sale de centrar la mascota en el título: el header ocupa
          // y=[48,111] y "AUTOnomIA" y=[48,89] (medido con tester.getRect).
          // Encima de la mascota van la etiqueta (16) y su separación (6), y
          // la caja de la mascota mide KigoDesign.ladoAsistente, así que el
          // dibujo queda centrado en 2 + 22 + 48 = 72 -- dentro de los 12px
          // de tolerancia del título y con la etiqueta todavía en pantalla.
          //
          // Era 12 cuando la mascota medía 76: crecer a 96 bajó el dibujo 10px
          // y lo sacó de esa tolerancia, así que este offset los devuelve.
          // rightDelBorde: 34 = el padding horizontal de PantallaAdaptable.
          topDelBorde: 2,
          rightDelBorde: _margenHorizontal,
          lado: _ladoAsistente(MediaQuery.sizeOf(context).width),
          mostrarEtiqueta: true,
          onRespuestaLibre: (_) {},
          onCampoExtraido: (_) {},
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Lo más ancho que puede ser el lockup sin meterse debajo de la mascota,
    // que flota pegada al borde derecho y fuera de esta fila. Va centrado en
    // pantalla (los dos extremos de la fila miden lo mismo), así que su mitad
    // derecha sólo tiene libre lo que hay entre el centro y el borde
    // izquierdo del dibujo. En el panel sobra de más; en un lienzo angosto es
    // lo que evita que el nombre termine pintado debajo de la mascota.
    final ancho = MediaQuery.sizeOf(context).width;
    final bordeIzquierdoMascota =
        ancho - _margenHorizontal - _ladoAsistente(ancho);
    final anchoMaxLockup = math.max(
      (bordeIzquierdoMascota - ancho / 2 - _aireLockupMascota) * 2,
      0.0,
    );

    return Row(
      children: [
        Presionable(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: _ladoBotonRegresar,
            height: _ladoBotonRegresar,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(_radioBotonRegresar),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: _tamanoFlechaRegresar,
            ),
          ),
        ),
        // Un `Expanded` con `Center` y no dos `Spacer` con el lockup en
        // medio: los `Spacer` son flex igual que él y le repartían un tercio
        // del sobrante, así que el `FittedBox` lo encogía aunque la fila
        // tuviera sitio de sobra. Con esto sólo encoge cuando no cabe, y
        // sigue centrado porque los dos extremos de la fila miden lo mismo.
        Expanded(
          child: Center(
            // Isotipo + nombre + subtítulo son una sola pieza y encogen
            // juntos: con el isotipo fuera del FittedBox, en una pantalla
            // angosta el texto se achicaba hasta ser ilegible mientras el
            // logo seguía enorme al lado.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaxLockup),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MarcaBadge(lado: _ladoLogoHeader),
                    const SizedBox(width: _huecoLogoNombre),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.t(context, 'kigo_label'),
                          style: TextStyle(
                            color: context.kTextPrimary,
                            fontSize: _fuenteNombreHeader,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: _huecoNombreSubtitulo),
                        Text(
                          AppLocalizations.t(context, 'self_checkin_label'),
                          style: TextStyle(
                            color: context.kTextSecondary,
                            fontSize: _fuenteSubtituloHeader,
                            letterSpacing: _espaciadoSubtituloHeader,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Hueco espejo del botón de regresar: es lo que mantiene el lockup
        // centrado en la pantalla.
        const SizedBox(width: _ladoBotonRegresar),
      ],
    );
  }

  Widget _buildAreaFacial() {
    // Responsivo en vez de un tamaño fijo en px: en pantallas más cortas que
    // el panel de referencia (800x1280) un marco fijo hacía que el
    // contenido de toda la columna no cupiera sin scroll. Mismo óvalo
    // (relación 1:1.25) que usa scanner_rostro_widget.dart en el registro
    // de visitante, y del mismo tamaño (no solo la misma proporción) -- el
    // primer intento lo dejó chico a propósito para caber junto al bloque
    // de PIN de abajo, pero eso lo hacía casi irreconocible como el mismo
    // reconocimiento facial. El PIN ahora es un botón compacto (ver
    // _buildPinFallback) para liberar ese espacio.
    final size = MediaQuery.sizeOf(context);
    final altoUtil = size.height - MediaQuery.paddingOf(context).vertical;
    // Las dos fracciones son topes contra cada eje, y mandan sólo donde el
    // lienzo da de sí. Eran 0.85 del ancho y 0.5 del alto: en el panel de
    // 800x1280 el segundo dejaba el óvalo en 640 y el bloque entero (texto,
    // óvalo, botón de PIN) flotaba con 56px muertos arriba y otros 56 abajo,
    // repartidos por los dos `Spacer` de la columna. 0.55 se los da al óvalo
    // -- 704 de alto, 563 de ancho -- y deja 23 de aire a cada lado, que es
    // lo que separa el bloque del header y de la franja de los botones
    // flotantes.
    //
    // El tope del ancho sube a 0.95 sólo para que deje de ser él quien manda
    // en el panel (0.85 lo clavaba en 680): el ancho real del óvalo lo sigue
    // dando la proporción 1:1.25 y, más abajo, `anchoMax` -- 563 de los 732
    // que deja el padding.
    //
    // En los lienzos cortos ninguna de las dos manda: ahí gobierna el tope
    // contra [_altoFijoColumna] de la línea siguiente, así que el óvalo mide
    // lo mismo que antes.
    double ovalH = math.min(size.width * 0.95, altoUtil * 0.55);
    // Sin scroll (ver desplazable: false arriba) el óvalo es la única pieza
    // elástica de la columna: todo lo demás -- header, instrucción, pastilla
    // de estado, botón de PIN, sus separaciones y los paddings de
    // PantallaAdaptable, con la reserva de los botones flotantes incluida --
    // suma [_altoFijoColumna]. Sin este tope, en un panel corto el 50% del
    // alto dejaba al botón de PIN debajo del micrófono.
    ovalH = math.max(
        _altoMinimoOvalo, math.min(ovalH, altoUtil - _altoFijoColumna));
    double ovalW = ovalH / 1.25;
    final anchoMax = size.width - 68; // 34 de padding horizontal a cada lado (ver PantallaAdaptable)
    if (ovalW > anchoMax) {
      ovalW = anchoMax;
      ovalH = ovalW * 1.25;
    }
    final colorGuia = _coincidenciaConfirmada ? const Color(0xFF2DCFA8) : KigoDesign.brand;

    return Column(
      children: [
        Text(
          AppLocalizations.t(context, 'mira_camara_identificarte'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 40),

        // Marco del área de cara: vista en vivo de la cámara frontal, con el
        // mismo tratamiento de óvalo guía que usa la captura de rostro del
        // registro de visitante (MarcoGuiaCamara) -- el aro cambia a verde
        // en cuanto se confirma la coincidencia, igual que allá.
        SizedBox(
          width: ovalW,
          height: ovalH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(child: _buildContenidoCamara()),
              MarcoGuiaCamara(
                ancho: ovalW,
                alto: ovalH,
                colorBorde: colorGuia,
                mostrarBarrido: _bucleVerificacionActivo && !_coincidenciaConfirmada,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildEstadoCamara(),
      ],
    );
  }

  /// Indicador de que el reconocimiento se está tomando de forma automática
  /// -- antes solo había un texto estático, sin ninguna señal de actividad
  /// en tiempo real (spinner mientras busca, check al confirmar), a
  /// diferencia del registro de visitante que sí lo tenía.
  Widget _buildEstadoCamara() {
    if (_coincidenciaConfirmada) {
      return _pillEstado(
        icono: const Icon(Icons.check_circle, color: Colors.white, size: 18),
        texto: AppLocalizations.t(context, 'rostro_detectado_capturando'),
        confirmado: true,
      );
    }
    if (_cameraController?.value.isInitialized == true) {
      return _pillEstado(
        icono: const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 2, color: KigoDesign.brand),
        ),
        texto: AppLocalizations.t(context, 'detectando_rostro_automaticamente'),
        confirmado: false,
      );
    }
    return Text(
      _textoEstadoCamara(),
      style: TextStyle(color: context.kTextTertiary, fontSize: 13, letterSpacing: 1.5),
    );
  }

  Widget _pillEstado({required Widget icono, required String texto, required bool confirmado}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: confirmado ? const Color(0xFF2DCFA8).withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: confirmado ? const Color(0xFF2DCFA8) : Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icono,
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: confirmado ? FontWeight.bold : FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenidoCamara() {
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 320,
          height: controller.value.previewSize?.width ?? 320,
          child: VistaPreviaCamara(controller),
        ),
      );
    }

    if (_camaraError != null) {
      return Center(
        child: Icon(
          Icons.videocam_off_outlined,
          size: 64,
          color: KigoDesign.brand.withValues(alpha: 0.5),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(
        color: KigoDesign.brand,
        strokeWidth: 2.5,
      ),
    );
  }

  String _textoEstadoCamara() {
    if (_cameraController?.value.isInitialized == true) {
      return AppLocalizations.t(context, 'detectando_rostro_automaticamente');
    }
    if (_camaraError != null) {
      return _camaraError!;
    }
    return AppLocalizations.t(context, 'activando_camara');
  }

  /// Antes era un bloque con texto "o bien" + botón -- se comprime a un solo
  /// botón compacto para liberar el espacio vertical que ahora usa el óvalo
  /// (mucho más grande, ver _buildAreaFacial).
  Widget _buildPinFallback() {
    final escala = _escalaPin(context);
    return Presionable(
      onTap: _irAlPin,
      // A 68 de alto la pastilla mide 284 de ancho, y en un lienzo de 320
      // (252 útiles) la etiqueta saltaba de renglón: el botón se estiraba a
      // 98 de alto y se montaba sobre los botones flotantes. Encogido entero
      // sigue siendo la misma pastilla de un renglón, más chica.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20 * escala,
            vertical: 12 * escala,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: KigoDesign.brand.withValues(alpha: 0.5),
              width: 1.5 * escala,
            ),
            borderRadius: BorderRadius.circular(14 * escala),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dialpad_rounded,
                color: KigoDesign.brand,
                size: 20 * escala,
              ),
              SizedBox(width: 8 * escala),
              // La pastilla se ajusta al texto (mainAxisSize.min). El
              // `Flexible` se queda por si alguien la monta con ancho
              // acotado: colgando del FittedBox recibe ancho libre y nunca
              // parte el renglón.
              Flexible(
                child: Text(
                  AppLocalizations.t(context, 'acceder_por_pin'),
                  style: TextStyle(
                    color: KigoDesign.brand,
                    fontSize: 15 * escala,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Diálogo de consentimiento específico para reconocimiento facial en el kiosko.
Future<bool> _mostrarConsentimientoFacial(BuildContext context) async {
  final bool? aceptado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: context.kSurfaceCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
      contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      title: Row(
        children: [
          const Icon(Icons.face_outlined, color: KigoDesign.brand, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLocalizations.t(context, 'aviso_privacidad_title'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.t(context, 'aviso_privacidad_content'),
        style: TextStyle(
          color: context.kTextSecondary,
          fontSize: 18,
          height: 1.6,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            AppLocalizations.t(context, 'back_button_text'),
            style: TextStyle(
              color: context.kTextSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            AppLocalizations.t(context, 'aceptar_button'),
            style: const TextStyle(
              color: KigoDesign.brand,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    ),
  );
  return aceptado ?? false;
}
