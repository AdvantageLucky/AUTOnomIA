import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/core/widgets/vista_previa_camara.dart';
import 'consent_dialog.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class EscaneoRostro extends StatefulWidget {
  const EscaneoRostro({super.key});

  @override
  State<EscaneoRostro> createState() => _EscaneoRostroState();
}

class _EscaneoRostroState extends State<EscaneoRostro> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Pide consentimiento antes de activar la cámara; solo la inicializa si acepta
    WidgetsBinding.instance.addPostFrameCallback((_) => _solicitarConsentimiento());
  }

  Future<void> _solicitarConsentimiento() async {
    final bool aceptado = await mostrarConsentimientoCamara(context);

    if (!mounted) return;

    if (aceptado) {
      _initCamera();
    } else {
      Navigator.pop(context); // El usuario presionó "Regresar"
    }
  }

  // Inicializa la cámara de rostro con los ajustes propios del hardware.
  // En el kiosko la lente correcta y la resolución vienen de AjustesCamara:
  // pedir `high` a un sensor de 2MP hace que la vista previa se congele.
  Future<void> _initCamera() async {
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
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
    }
  }

  // Función para tomar la foto y mandarla a procesar
  Future<void> _tomarFotoYProcesar() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Captura la foto localmente
      final XFile foto = await _controller!.takePicture();
      
      if (mounted) {
        // Regresamos ÚNICAMENTE la ruta de la foto (String) a la vista principal
        Navigator.pop(context, foto.path);
      }
    } catch (e) {
      debugPrint("Error al capturar la foto: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Muy importante liberar la cámara al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: KigoDesign.bgDark,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF542F))),
      );
    }

    final size = MediaQuery.of(context).size;
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.25;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KigoDesign.bgDark,
        title: Text(AppLocalizations.t(context, 'apunta_a_tu_rostro'), style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Botón físico/virtual para regresar
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: VistaPreviaCamara(_controller!),
          ),

          // Overlay oscuro con recorte oval
          Positioned.fill(
            child: CustomPaint(
              painter: _OvalOverlayPainter(ovalW, ovalH),
            ),
          ),

          // Guía oval con borde naranja — se dibuja el óvalo real con
          // CustomPaint: un Border.all() sobre BorderRadius circular al 50%
          // en un rectángulo no cuadrado deja costuras visibles a los lados.
          Center(
            child: SizedBox(
              width: ovalW,
              height: ovalH,
              child: CustomPaint(painter: _OvaloGuiaPainter()),
            ),
          ),

          // Instrucción
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Text(
              AppLocalizations.t(context, 'centra_rostro_ovalo'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // Botón de captura
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFFF542F), // naranja de Kigo
                onPressed: _tomarFotoYProcesar,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  final double ovalW;
  final double ovalH;

  _OvalOverlayPainter(this.ovalW, this.ovalH);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final oval = Rect.fromCenter(center: Offset(cx, cy), width: ovalW, height: ovalH);
    final path = Path()
      ..addRect(full)
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OvaloGuiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF542F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rect = Offset.zero & size;
    canvas.drawOval(rect.deflate(1.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}