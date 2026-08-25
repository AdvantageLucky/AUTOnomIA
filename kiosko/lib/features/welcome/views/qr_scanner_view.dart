import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:kigo_kiosco/core/notifiers/kiosko_config_notifier.dart';
import 'package:kigo_kiosco/core/routing/registro_router.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/persona_qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_result_view.dart';
import 'package:kigo_kiosco/features/welcome/views/persona_qr_result_view.dart';
import 'package:kigo_kiosco/features/welcome/views/widgets/kigo_wordmark.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Pantalla de entrada del kiosko: escanea sola, sin toque previo. Detecta
/// tanto el QR personal de la app Kigo como el token de invitación de
/// siempre. [onSinCodigo] es la única salida — quien no trae ningún código
/// cae al flujo manual existente.
class QrScannerView extends StatefulWidget {
  final QrScannerViewModel viewModel;
  final VoidCallback onSinCodigo;

  const QrScannerView({super.key, required this.viewModel, required this.onSinCodigo});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> with SingleTickerProviderStateMixin {
  bool _consentGiven = false;
  bool _readyToScan = false;
  MobileScannerController? _controller;
  late final AnimationController _anilloCtrl;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);
    _anilloCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
    _anilloCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _updateView() => setState(() {});

  Future<void> _solicitarConsentimiento() async {
    final bool aceptado = await mostrarConsentimientoCamara(context);
    if (!mounted) return;
    if (aceptado) {
      setState(() {
        _consentGiven = true;
        _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
      });
      _iniciarEscaneo();
    } else {
      // No hay a dónde regresar — es la pantalla de entrada. Reintentamos el
      // consentimiento en vez de dejar al kiosko sin nada que mostrar.
      _solicitarConsentimiento();
    }
  }

  Future<void> _iniciarEscaneo() async {
    // Reiniciar el controller para limpiar el caché de noDuplicates.
    _controller?.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _controller?.start();
    setState(() => _readyToScan = true);
  }

  void _onQrDetected(String value) {
    if (widget.viewModel.isScanned) return;
    widget.viewModel.onQrDetected(value);
    _controller?.stop();

    final navigator = Navigator.of(context);

    // El QR personal de la app Kigo (persona_id:firma) siempre identifica
    // por completo a quien lo trae — a diferencia del token de invitación,
    // no hay reglas de captura del kiosko que aplicarle.
    if (value.contains(':')) {
      Future.delayed(const Duration(milliseconds: 900), () {
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => PersonaQrResultView(
            viewModel: PersonaQrResultViewModel(qrValue: value),
            alTerminar: () => _reiniciar(navigator),
          ),
        ));
      });
      return;
    }

    final config = context.read<KioskoConfigNotifier>().config;

    // Si la config no pide capturas al invitado, el QR basta: se consume la
    // invitación de inmediato como siempre.
    if (!RegistroRouter.invitadoRequiereCapturas(config)) {
      Future.delayed(const Duration(milliseconds: 900), () {
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => QrResultView(
            viewModel: QrResultViewModel(token: value),
            alTerminar: () => _reiniciar(navigator),
          ),
        ));
      });
      return;
    }

    _continuarConCapturas(value);
  }

  /// Vuelve a montar la pantalla de escaneo desde cero para el siguiente
  /// visitante — cada persona da su propio consentimiento de cámara.
  void _reiniciar(NavigatorState navigator) {
    navigator.pushReplacement(MaterialPageRoute(
      builder: (_) => QrScannerView(viewModel: QrScannerViewModel(), onSinCodigo: widget.onSinCodigo),
    ));
  }

  /// El invitado tiene que dejar evidencia (placa, rostro o INE) antes de que la
  /// invitación se consuma. Se valida el token primero para no mandarlo a tomar
  /// fotos si el QR ya venció, y para saber a nombre de quién va la visita.
  Future<void> _continuarConCapturas(String token) async {
    final config = context.read<KioskoConfigNotifier>().config;
    final servicio = context.read<KioskoServicio>();
    final navigator = Navigator.of(context);

    try {
      final invitacion = await servicio.validarInvitacion(token);
      if (!mounted) return;

      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => RegistroRouter.paraInvitado(
          config,
          token: token,
          titular: invitacion['titular'] as String?,
          casaDestino: invitacion['casa_destino'] as String?,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      // QrResultView ya sabe mostrar el error de una invitación inválida.
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => QrResultView(
          viewModel: QrResultViewModel(token: token),
          alTerminar: () => _reiniciar(navigator),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_consentGiven && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: (capture) {
                if (!_readyToScan) return;
                final barcode = capture.barcodes.firstOrNull;
                final value = barcode?.rawValue;
                if (value != null) _onQrDetected(value);
              },
            ),

          AnimatedBuilder(
            animation: _anilloCtrl,
            builder: (context, _) => CustomPaint(
              painter: _QrOverlayPainter(
                scanned: widget.viewModel.isScanned,
                pulso: _anilloCtrl.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const KigoWordmark(),
                  const Spacer(),
                  _buildBottomHint(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHint() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.viewModel.isScanned
                ? AppLocalizations.t(context, 'codigo_detectado')
                : AppLocalizations.t(context, 'apunta_al_codigo_qr'),
            key: ValueKey(widget.viewModel.isScanned),
            style: TextStyle(
              color: widget.viewModel.isScanned ? KigoDesign.success : Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.t(context, 'codigo_personal_o_invitacion'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: widget.onSinCodigo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              AppLocalizations.t(context, 'no_tengo_app_o_qr'),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/// El motivo de firma de todo el flujo QR: un solo anillo continuo que
/// respira mientras espera (en vez del típico marco de esquinas) y se cierra
/// en un gesto rápido y sin rebote al detectar un código — mismo lenguaje
/// visual que retoman las pantallas de resultado.
class _QrOverlayPainter extends CustomPainter {
  final bool scanned;
  final double pulso;
  const _QrOverlayPainter({required this.scanned, required this.pulso});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);

    final cutBase = size.width * 0.66;
    // Respiración sutil (0.97–1.0) mientras espera; sólido y estable ya detectado.
    final escala = scanned ? 1.0 : 0.97 + (0.03 * pulso);
    final cutSize = cutBase * escala;
    final left = (size.width - cutSize) / 2;
    final top = (size.height - cutSize) / 2;
    final rect = Rect.fromLTWH(left, top, cutSize, cutSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    final color = scanned ? KigoDesign.success : KigoDesign.brand;
    final opacidadAnillo = scanned ? 1.0 : 0.55 + (0.35 * pulso);

    // Resplandor suave detrás del anillo — la profundidad que separa esto de
    // un simple marco plano.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * opacidadAnillo)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(rrect, glowPaint);

    final ringPaint = Paint()
      ..color = color.withValues(alpha: opacidadAnillo)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scanned ? 3.5 : 2.5;
    canvas.drawRRect(rrect, ringPaint);
  }

  @override
  bool shouldRepaint(_QrOverlayPainter oldDelegate) =>
      oldDelegate.scanned != scanned || oldDelegate.pulso != pulso;
}
