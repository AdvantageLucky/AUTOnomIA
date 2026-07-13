import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'consent_dialog.dart';

class EscaneoRostro extends StatefulWidget {
  const EscaneoRostro({Key? key}) : super(key: key);

  @override
  State<EscaneoRostro> createState() => _EscaneoRostroState();
}

class _EscaneoRostroState extends State<EscaneoRostro> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
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

  // Inicializa la cámara frontal del dispositivo (para el rostro del usuario)
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      // Buscamos la cámara frontal; si no existe, usamos la primera disponible
      final frontal = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        frontal,
        ResolutionPreset.high,
        enableAudio: false, // Apagamos el audio ya que solo queremos foto
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        print("Error al inicializar la cámara: $e");
      }
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
      print("Error al capturar la foto: $e");
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
        backgroundColor: Color(0xFF171313),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF542F))),
      );
    }

    final size = MediaQuery.of(context).size;
    final ovalW = size.width * 0.72;
    final ovalH = ovalW * 1.25;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF171313),
        title: const Text("Apunta a tu rostro", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Botón físico/virtual para regresar
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Overlay oscuro con recorte oval
          Positioned.fill(
            child: CustomPaint(
              painter: _OvalOverlayPainter(ovalW, ovalH),
            ),
          ),

          // Guía oval con borde naranja
          Center(
            child: Container(
              width: ovalW,
              height: ovalH,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(ovalW / 2),
                border: Border.all(color: const Color(0xFFFF542F), width: 3),
              ),
            ),
          ),

          // Instrucción
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: const Text(
              'Centra tu rostro dentro del óvalo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
    final oval = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: ovalW, height: ovalH),
      Radius.circular(ovalW / 2),
    );
    final path = Path()
      ..addRect(full)
      ..addRRect(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}