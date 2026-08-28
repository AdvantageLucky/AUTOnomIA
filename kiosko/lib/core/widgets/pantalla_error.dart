import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

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
    // Sin MaterialApp encima: ErrorWidget puede dispararse por debajo de él,
    // así que el modo claro/oscuro se lee de la bandera que deja main.dart y
    // no de `Theme.of`.
    final claro = kigoTemaClaroActivo;
    final fondo = claro ? KigoDesign.bgLight : KigoDesign.bgDark;
    final textoPrincipal = claro ? KigoDesign.textDark : KigoDesign.textPrimary;
    final textoSecundario =
        claro ? KigoDesign.textSecondaryLight : KigoDesign.textSecondary;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: fondo,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'La aplicación encontró un error',
                  style: TextStyle(
                    color: KigoDesign.brand,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Muestra esta pantalla a soporte técnico.',
                  style: TextStyle(color: textoSecundario, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      detalle == null ? mensaje : '$mensaje\n\n$detalle',
                      style: TextStyle(
                        color: textoPrincipal,
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
                      backgroundColor: KigoDesign.brand,
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
