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
          // Mismo header que WelcomeView (PantallaAdaptable, padding 48/34).
          topDelBorde: 48,
          rightDelBorde: 34,
          mostrarEtiqueta: true,
          onRespuestaLibre: (_) {},
          onCampoExtraido: (_) {},
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Presionable(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KigoDesign.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        const MarcaBadge(lado: 48),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.t(context, 'kigo_label'),
              style: TextStyle(
                color: context.kTextPrimary,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.t(context, 'self_checkin_label'),
              style: TextStyle(
                color: context.kTextSecondary,
                fontSize: 14,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 44),
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
    double ovalH = math.min(size.width * 0.85, size.height * 0.5);
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
    return Presionable(
      onTap: _irAlPin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: KigoDesign.brand.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dialpad_rounded,
              color: KigoDesign.brand,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.t(context, 'acceder_por_pin'),
              style: const TextStyle(
                color: KigoDesign.brand,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
