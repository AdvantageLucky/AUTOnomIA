import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';

/// Convierte un frame en vivo (`CameraController.startImageStream`) al
/// formato que espera ML Kit.
///
/// Solo funciona si la cámara se abrió con
/// `imageFormatGroup: ImageFormatGroup.nv21` (ver
/// `CamaraKiosko.controlador`), que entrega un solo plano -- con el formato
/// multi-plano por default de Android (YUV_420_888, 3 planos) esto siempre
/// regresa null, que es justo lo que se quiere: mejor descartar el frame
/// que alimentarle a ML Kit bytes en un formato que no pidió.
///
/// La rotación NO sale de `CameraDescription.sensorOrientation` -- el HAL
/// de este equipo lo reporta mal (ver comentario en `AjustesCamara`) --
/// sale del mismo cuarto de giro ya calibrado a mano que usa la vista
/// previa (`AjustesCamara.cuartosDeGiro`): si algún día se reprovisiona un
/// equipo con otro montaje físico, ajustar esa única constante corrige la
/// vista Y el reconocimiento a la vez, en vez de tener dos números de
/// rotación que calibrar por separado y que puedan desalinearse entre sí.
InputImage? convertirFrameAInputImage(CameraImage frame) {
  if (frame.planes.length != 1) return null;

  final formatoCrudo = InputImageFormatValue.fromRawValue(frame.format.raw);
  if (formatoCrudo != InputImageFormat.nv21) return null;
  const formato = InputImageFormat.nv21;

  final grados = (AjustesCamara.cuartosDeGiro * 90) % 360;
  final rotacion = InputImageRotationValue.fromRawValue(grados) ?? InputImageRotation.rotation0deg;

  final plane = frame.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(frame.width.toDouble(), frame.height.toDouble()),
      rotation: rotacion,
      format: formato,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
