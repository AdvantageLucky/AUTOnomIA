import 'dart:async';
import 'dart:io';

import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/pantalla_adaptable.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
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

  final _reconocimientoServicio = ReconocimientoFacialServicio();
  Timer? _timerVerificacion;
  bool _verificandoRostro = false;

  // Exigimos 2 coincidencias seguidas contra el mismo residente antes de dar
  // el acceso por bueno (mitigación básica de falsos positivos/spoofing).
  String? _ultimoNombreCoincidente;
  String? _ultimaCasaCoincidente;
  int _coincidenciasConsecutivas = 0;

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
      _timerVerificacion?.cancel();
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

      _timerVerificacion = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _intentarVerificarRostro(),
      );
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
      if (mounted) {
        setState(() {
          _camaraInicializando = false;
          _camaraError = AppLocalizations.t(context, 'no_se_pudo_activar_camara');
        });
      }
    }
  }

  // Toma una foto silenciosa, valida que haya un rostro, calcula su huella
  // localmente y la manda a comparar contra los residentes del edificio.
  Future<void> _intentarVerificarRostro() async {
    if (_verificandoRostro) return;
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }

    _verificandoRostro = true;
    XFile? foto;
    try {
      foto = await controller.takePicture();

      // Una sola pasada de ML Kit por foto: calcularEmbedding ya detecta el
      // rostro y descarta los que vienen demasiado pequeños.
      final embedding = await _reconocimientoServicio.calcularEmbedding(foto.path);
      if (embedding == null) {
        _coincidenciasConsecutivas = 0;
        return;
      }

      final resultado = await KioskoServicio().verificarRostroResidente(embedding);
      _registrarCoincidencia(
        resultado['nombre'] as String?,
        resultado['casa_destino'] as String?,
      );
    } catch (e) {
      // Sin match, sin red, etc. — seguimos intentando en el siguiente tick;
      // el acceso por PIN sigue disponible como respaldo en todo momento.
      _coincidenciasConsecutivas = 0;
    } finally {
      _verificandoRostro = false;
      final rutaFoto = foto?.path;
      if (rutaFoto != null) {
        unawaited(Future(() async {
          try {
            await File(rutaFoto).delete();
          } catch (_) {}
        }));
      }
    }
  }

  void _registrarCoincidencia(String? nombre, String? casaDestino) {
    if (nombre == _ultimoNombreCoincidente && casaDestino == _ultimaCasaCoincidente) {
      _coincidenciasConsecutivas++;
    } else {
      _ultimoNombreCoincidente = nombre;
      _ultimaCasaCoincidente = casaDestino;
      _coincidenciasConsecutivas = 1;
    }

    if (_coincidenciasConsecutivas >= 2 && mounted) {
      _timerVerificacion?.cancel();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResidentWelcomeView(
          viewModel: ResidentWelcomeViewModel(
            nombre: nombre ?? AppLocalizations.t(context, 'residente_label'),
            casaDestino: casaDestino ?? '',
          ),
        ),
      ));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerVerificacion?.cancel();
    unawaited(_reconocimientoServicio.dispose());
    _cameraController?.dispose();
    super.dispose();
  }

  void _irAlPin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResidentPinView(viewModel: ResidentPinViewModel()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoConsent) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: Center(
          child: CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.kBg,
      body: PantallaAdaptable(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
        child: Column(
          children: [
            _buildHeader(context),
            const Spacer(),
            _buildAreaFacial(),
            const SizedBox(height: 40),
            _buildPinFallback(),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
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
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: KigoDesign.brand,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'K',
              style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.t(context, 'kigo_label'),
                style: TextStyle(color: context.kTextPrimary, fontSize: 29, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(AppLocalizations.t(context, 'self_checkin_label'),
                style: TextStyle(color: context.kTextSecondary, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildAreaFacial() {
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

        // Marco del área de cara: muestra la vista en vivo de la cámara frontal
        Container(
          width: 320,
          height: 320,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.kSurface2,
            border: Border.all(color: KigoDesign.brand.withValues(alpha: 0.35), width: 2.5),
          ),
          child: _buildContenidoCamara(),
        ),

        const SizedBox(height: 20),
        Text(
          _textoEstadoCamara(),
          style: TextStyle(
            color: context.kTextTertiary,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ],
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
      child: CircularProgressIndicator(color: KigoDesign.brand, strokeWidth: 2.5),
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

  Widget _buildPinFallback() {
    return Column(
      children: [
        Text(
          AppLocalizations.t(context, 'o_bien'),
          style: TextStyle(color: context.kTextTertiary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _irAlPin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: KigoDesign.brand.withValues(alpha: 0.5), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dialpad_rounded, color: KigoDesign.brand, size: 22),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.t(context, 'acceder_por_pin'),
                  style: const TextStyle(
                    color: KigoDesign.brand,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      AppLocalizations.t(context, 'footer_text'),
      style: TextStyle(color: context.kTextTertiary, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w500),
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
              style: TextStyle(color: context.kTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.t(context, 'aviso_privacidad_content'),
        style: TextStyle(color: context.kTextSecondary, fontSize: 18, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.t(context, 'back_button_text'),
              style: TextStyle(color: context.kTextSecondary, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.t(context, 'aceptar_button'),
              style: const TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    ),
  );
  return aceptado ?? false;
}
