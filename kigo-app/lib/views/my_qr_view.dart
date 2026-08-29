import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

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
    // El PIN vive en la membresía: lo genera el backend al unirse al centro
    // y no cambia, así que basta con leerlo del estado ya cargado.
    final membresia = context.watch<AuthViewModel>().centroActivo;
    final pin = membresia?.status == 'rechazado' ? '' : (membresia?.pin ?? '');

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
                        // El recuadro del QR ocupa el mismo ancho que el del
                        // PIN (ambos double.infinity) y el AspectRatio lo deja
                        // cuadrado, así que el QR escala con el ancho útil.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: QrImageView(data: _dato!),
                          ),
                        ),
                        if (pin.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _CuadroPin(pin: pin),
                        ],
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

/// Recuadro naranja con el PIN debajo del QR — la única forma que tiene el
/// residente de conocerlo, porque ya no lo elige él.
class _CuadroPin extends StatelessWidget {
  final String pin;
  const _CuadroPin({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TU PIN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            // letterSpacing también se aplica después del último dígito:
            // este padding compensa para que el número quede centrado.
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              pin,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
