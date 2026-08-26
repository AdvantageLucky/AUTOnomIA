import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camara_kiosko.dart';

/// Vista previa de cámara con la rotación corregida a mano.
///
/// `CameraPreview` calcula el giro con el `sensorOrientation` que reporta el
/// HAL. El kiosko reporta un valor equivocado y la imagen sale de cabeza, así
/// que aquí se aplica el giro fijo de [AjustesCamara.cuartosDeGiro].
class VistaPreviaCamara extends StatelessWidget {
  const VistaPreviaCamara(this.controller, {super.key, this.child});

  final CameraController controller;

  /// Contenido superpuesto (guías, marcos). No se gira con la imagen.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget preview = CameraPreview(controller);

    // RotatedBox gira en tiempo de layout, no solo al pintar: el tamaño que ve
    // el padre ya viene corregido y `BoxFit.cover` no deforma la imagen.
    if (AjustesCamara.cuartosDeGiro % 4 != 0) {
      preview = RotatedBox(
        quarterTurns: AjustesCamara.cuartosDeGiro,
        child: preview,
      );
    }

    if (!AjustesCamara.espejar &&
        controller.description.lensDirection == CameraLensDirection.front) {
      // El plugin ya espeja la lente frontal; esto lo revierte cuando el kiosko
      // debe mostrar la imagen tal como la ve la cámara.
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: preview,
      );
    }

    if (child == null) return preview;
    return Stack(fit: StackFit.expand, children: [preview, child!]);
  }
}
