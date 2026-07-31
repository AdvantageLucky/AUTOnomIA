import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/consent_dialog.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_scanner_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/viewmodels/qr_result_viewmodel.dart';
import 'package:kigo_kiosco/features/welcome/views/qr_result_view.dart';

class QrScannerView extends StatefulWidget {
  final QrScannerViewModel viewModel;

  const QrScannerView({super.key, required this.viewModel});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  bool _consentGiven = false;
  bool _readyToScan = false;
  bool _scanStarted = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_updateView);
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateView);
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
        _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _iniciarEscaneo() async {
    if (_scanStarted) return;
    setState(() => _scanStarted = true);
    // Reiniciar el controller para limpiar el caché de noDuplicates
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
    Future.delayed(const Duration(milliseconds: 1200), () {
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => QrResultView(
          viewModel: QrResultViewModel(token: value),
        ),
      ));
    });
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

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: CustomPaint(
              key: ValueKey(widget.viewModel.isScanned),
              painter: _QrOverlayPainter(scanned: widget.viewModel.isScanned),
              child: const SizedBox.expand(),
            ),
          ),

          // Botón de inicio de escaneo — centrado en el recuadro del QR
          if (_consentGiven && !_scanStarted && !widget.viewModel.isScanned)
            GestureDetector(
              onTap: _iniciarEscaneo,
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF542F).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF542F), width: 2),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFFFF542F),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Toca para escanear',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (widget.viewModel.isScanned)
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.12),
                child: AnimatedOpacity(
                  opacity: widget.viewModel.isScanned ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 22),
                        SizedBox(width: 10),
                        Text(
                          '¡Código detectado!',
                          style: TextStyle(color: Color(0xFF22C55E), fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildTopBar(context),
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF542F), size: 18),
              SizedBox(width: 8),
              Text(
                'Escanea tu invitación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Column(
      children: [
        Text(
          _readyToScan
              ? 'Apunta al código QR de tu invitación'
              : 'Posiciona el código QR y toca para escanear',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _readyToScan ? 'El código se detectará automáticamente' : 'La cámara no escaneará hasta que toques',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  final bool scanned;
  const _QrOverlayPainter({this.scanned = false});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.62);

    final cutSize = size.width * 0.68;
    final left = (size.width - cutSize) / 2;
    final top = (size.height - cutSize) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cutSize, cutSize),
        const Radius.circular(16),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    final cornerPaint = Paint()
      ..color = scanned ? const Color(0xFF22C55E) : const Color(0xFFFF542F)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cl = cutSize * 0.12;
    const r = 16.0;

    // Superior izquierda
    canvas.drawLine(Offset(left + r, top), Offset(left + r + cl, top), cornerPaint);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + cl), cornerPaint);

    // Superior derecha
    canvas.drawLine(Offset(left + cutSize - r, top), Offset(left + cutSize - r - cl, top), cornerPaint);
    canvas.drawLine(Offset(left + cutSize, top + r), Offset(left + cutSize, top + r + cl), cornerPaint);

    // Inferior izquierda
    canvas.drawLine(Offset(left + r, top + cutSize), Offset(left + r + cl, top + cutSize), cornerPaint);
    canvas.drawLine(Offset(left, top + cutSize - r), Offset(left, top + cutSize - r - cl), cornerPaint);

    // Inferior derecha
    canvas.drawLine(Offset(left + cutSize - r, top + cutSize), Offset(left + cutSize - r - cl, top + cutSize), cornerPaint);
    canvas.drawLine(Offset(left + cutSize, top + cutSize - r), Offset(left + cutSize, top + cutSize - r - cl), cornerPaint);
  }

  @override
  bool shouldRepaint(_QrOverlayPainter oldDelegate) => oldDelegate.scanned != scanned;
}
