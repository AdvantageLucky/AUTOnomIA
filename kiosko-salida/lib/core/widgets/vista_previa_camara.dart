import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camara_kiosko.dart';

/// Vista previa de cámara con la rotación corregida a mano -- copiado de
/// kiosko/lib/core/widgets/vista_previa_camara.dart, mismo mecanismo.
class VistaPreviaCamara extends StatelessWidget {
  const VistaPreviaCamara(this.controller, {super.key, this.child});

  final CameraController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget preview = CameraPreview(controller);

    if (AjustesCamara.cuartosDeGiro % 4 != 0) {
      preview = RotatedBox(
        quarterTurns: AjustesCamara.cuartosDeGiro,
        child: preview,
      );
    }

    if (!AjustesCamara.espejar &&
        controller.description.lensDirection == CameraLensDirection.front) {
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
