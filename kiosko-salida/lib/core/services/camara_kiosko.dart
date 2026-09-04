import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ajustes de cámara -- mismo mecanismo que kiosko/lib/core/services/camara_kiosko.dart:
/// el hardware real (F10 u otra tablet) puede montar la lente al revés o
/// reportar mal cuál lente es cuál, así que estos valores se calibran por
/// dispositivo vía --dart-define, no se deducen en código.
class AjustesCamara {
  const AjustesCamara._();

  /// Cuartos de giro sobre la vista previa.
  static const int cuartosDeGiro =
      int.fromEnvironment('SALIDA_CAM_ROTACION', defaultValue: 0);

  /// Índice fijo de la lente frontal (-1 = resolver por lensDirection).
  static const int indiceFrontal =
      int.fromEnvironment('SALIDA_CAM_FRONTAL', defaultValue: -1);

  /// Espejo horizontal de la vista previa frontal.
  static const bool espejar =
      bool.fromEnvironment('SALIDA_CAM_ESPEJO', defaultValue: true);

  /// Resolución de captura de rostro.
  static const ResolutionPreset resolucionRostro = ResolutionPreset.medium;
}

/// Selección y diagnóstico de la cámara del dispositivo -- mismo patrón que
/// kiosko/lib/core/services/camara_kiosko.dart, simplificado: esta app solo
/// necesita la lente frontal (nunca escanea documentos ni placas).
class CamaraKiosko {
  const CamaraKiosko._();

  static List<CameraDescription>? _cache;

  static Future<List<CameraDescription>> disponibles() async {
    if (_cache != null) return _cache!;

    final camaras = await availableCameras();
    for (var i = 0; i < camaras.length; i++) {
      final c = camaras[i];
      debugPrint(
        '[camara] #$i name=${c.name} '
        'lente=${c.lensDirection.name} sensorOrientation=${c.sensorOrientation}',
      );
    }
    _cache = camaras;
    return camaras;
  }

  static Future<CameraDescription> paraRostro() async {
    final camaras = await disponibles();
    if (camaras.isEmpty) {
      throw CameraException('sin_camara', 'El dispositivo no reporta cámaras');
    }

    final indiceFijo = AjustesCamara.indiceFrontal;
    if (indiceFijo >= 0) {
      if (indiceFijo < camaras.length) return camaras[indiceFijo];
      debugPrint(
        '[camara] la lente #$indiceFijo no existe '
        '(${camaras.length} detectadas); se usa detección automática',
      );
    }

    return camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => camaras.first,
    );
  }

  static Future<void> inicializar(CameraController controller) async {
    await controller.initialize();
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (e) {
      debugPrint('[camara] no se pudo fijar la orientación: $e');
    }
  }

  static CameraController controlador(
    CameraDescription camara,
    ResolutionPreset resolucion,
  ) {
    return CameraController(
      camara,
      resolucion,
      enableAudio: false,
    );
  }
}
