import 'package:flutter/material.dart';

/// Contenedor estándar del cuerpo de una pantalla.
///
/// Resuelve de una vez los tres problemas de layout que se repetían por el
/// proyecto en el panel del kiosko (800x1280):
///
/// * **Ocupa todo.** Sin esto, una `Column` bajo restricciones sueltas —el caso
///   de cualquier hijo no posicionado de un `Stack`— se encoge al ancho de su
///   hijo más ancho y se pega arriba a la izquierda.
/// * **No desborda.** El contenido scrollea cuando no cabe, en vez de recortarse
///   o pintar las franjas de overflow.
/// * **Respeta los `Spacer`.** `ConstrainedBox` + `IntrinsicHeight` le dan a la
///   columna al menos el alto del viewport, así los `Spacer` siguen repartiendo
///   el espacio sobrante como en una pantalla fija.
class PantallaAdaptable extends StatelessWidget {
  const PantallaAdaptable({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
    this.conSafeArea = true,
  });

  /// Normalmente una `Column`, con o sin `Spacer`.
  final Widget child;

  final EdgeInsets padding;

  /// Desactivar cuando el llamador ya envuelve en `SafeArea` o cuando la
  /// pantalla dibuja a sangre (una vista previa de cámara a pantalla completa).
  final bool conSafeArea;

  @override
  Widget build(BuildContext context) {
    final cuerpo = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(padding: padding, child: child),
            ),
          ),
        );
      },
    );

    return SizedBox.expand(
      child: conSafeArea ? SafeArea(child: cuerpo) : cuerpo,
    );
  }
}
