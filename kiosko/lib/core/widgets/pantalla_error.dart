import 'package:flutter/material.dart';

/// Cuenta de reinicios del árbol de widgets. Cambiarla vuelve a construir la
/// app entera sin reinstalar ni matar el proceso.
final ValueNotifier<int> generacionApp = ValueNotifier(0);

/// Último error capturado, para poder mostrarlo aunque no reviente el build.
final ValueNotifier<String?> ultimoError = ValueNotifier(null);

/// Sustituye la pantalla gris que Flutter muestra en release cuando un widget
/// falla al construirse o al medirse.
///
/// El kiosko se actualiza por Bluetooth y no tiene `adb` a la mano: sin esto,
/// cualquier excepción se ve como "la app se congeló" y no hay forma de saber
/// qué pasó. Aquí el error queda en pantalla y se puede reiniciar en sitio.
class PantallaError extends StatelessWidget {
  const PantallaError({super.key, required this.mensaje, this.detalle});

  final String mensaje;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    // Sin MaterialApp encima: ErrorWidget puede dispararse por debajo de él.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF09090D),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La aplicación encontró un error',
                  style: TextStyle(
                    color: Color(0xFFFF542F),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Muestra esta pantalla a soporte técnico.',
                  style: TextStyle(color: Color(0xFF888AA6), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      detalle == null ? mensaje : '$mensaje\n\n$detalle',
                      style: const TextStyle(
                        color: Color(0xFFECEAF4),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF542F),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ultimoError.value = null;
                      generacionApp.value++;
                    },
                    child: const Text(
                      'Reiniciar la aplicación',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
