import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MyQrView extends StatefulWidget {
  const MyQrView({super.key});

  @override
  State<MyQrView> createState() => _MyQrViewState();
}

class _MyQrViewState extends State<MyQrView> {
  String? _dato;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService().get('/personas/me/qr');
      // Formato del QR: "<persona_id>:<firma>" — el kiosko lo parte por el
      // primer ':' al escanear (ver POST /kioskos/:id/personas/verificar-qr).
      setState(() => _dato = '${data['persona_id']}:${data['firma']}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _cargando
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: QrImageView(data: _dato!, size: 220),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Muéstralo en la caseta o el kiosko de cualquier centro donde tengas acceso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textDimmed, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
