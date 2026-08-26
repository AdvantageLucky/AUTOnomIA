import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ajustes de cámara del kiosko (panel 10" 800*1280, cámara dual RGB+IR).
///
/// Estos valores salieron de calibrar sobre el equipo real y no se pueden
/// deducir en código: el HAL reporta mal `sensorOrientation` y expone las dos
/// lentes (RGB e IR) como frontales, en un orden que no corresponde al uso.
///
/// Siguen siendo sobreescribibles por `--dart-define` para provisionar un
/// equipo con otra configuración de montaje.
class AjustesCamara {
  const AjustesCamara._();

  /// Cuartos de giro sobre la vista previa. El módulo va montado invertido
  /// respecto al panel, de ahí los 180°.
  static const int cuartosDeGiro =
      int.fromEnvironment('KIOSKO_CAM_ROTACION', defaultValue: 2);

  /// Lente para rostro. La #1 es la infrarroja de visión nocturna: entrega
  /// una imagen monocroma sin color útil para reconocimiento facial.
  static const int indiceFrontal =
      int.fromEnvironment('KIOSKO_CAM_FRONTAL', defaultValue: 0);

  /// Lente para documentos: la misma RGB, que es la única que da color.
  static const int indiceDocumento =
      int.fromEnvironment('KIOSKO_CAM_DOCUMENTO', defaultValue: 0);

  /// Espejo horizontal de la vista previa frontal.
  static const bool espejar =
      bool.fromEnvironment('KIOSKO_CAM_ESPEJO', defaultValue: true);

  /// Resolución de captura de rostro. En el kiosko (2MP, 2GB RAM) pedir `high`
  /// impide al HAL reservar buffers y la vista previa se congela.
  static const ResolutionPreset resolucionRostro = ResolutionPreset.medium;

  /// Resolución de lectura de documentos.
  ///
  /// Tiene que ser alta: a 720x480 el texto de una INE queda en unos pocos
  /// píxeles de alto y el OCR no lo puede leer por muy enfocada que esté la
  /// imagen. Se bajó a `medium` cuando peleábamos contra el congelamiento de
  /// Camera2; con CameraX ya no hace falta.
  static const ResolutionPreset resolucionDocumento = ResolutionPreset.veryHigh;
}

/// Selección y diagnóstico de las cámaras del dispositivo.
class CamaraKiosko {
  const CamaraKiosko._();

  static List<CameraDescription>? _cache;

  /// Enumera las cámaras y deja constancia de lo que reporta el HAL.
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

  /// Lente para capturar rostros.
  static Future<CameraDescription> paraRostro() =>
      _elegir(AjustesCamara.indiceFrontal, CameraLensDirection.front);

  /// Lente para capturar documentos.
  static Future<CameraDescription> paraDocumento() =>
      _elegir(AjustesCamara.indiceDocumento, CameraLensDirection.back);

  static Future<CameraDescription> _elegir(
    int indiceFijo,
    CameraLensDirection preferida,
  ) async {
    final camaras = await disponibles();
    if (camaras.isEmpty) {
      throw CameraException('sin_camara', 'El dispositivo no reporta cámaras');
    }

    // El índice fijo gana sobre cualquier heurística: en el kiosko la lente
    // correcta no se puede deducir de `lensDirection`, porque tanto la RGB
    // como la IR se reportan como frontales.
    if (indiceFijo >= 0) {
      if (indiceFijo < camaras.length) return camaras[indiceFijo];
      debugPrint(
        '[camara] la lente #$indiceFijo no existe '
        '(${camaras.length} detectadas); se usa detección automática',
      );
    }

    return camaras.firstWhere(
      (c) => c.lensDirection == preferida,
      orElse: () => camaras.first,
    );
  }

  /// Inicializa el controlador y fija la orientación de captura.
  ///
  /// Los kioskos de pared normalmente no traen acelerómetro. Sin él, Android
  /// reporta una orientación arbitraria y el plugin calcula mal el giro de la
  /// vista previa. Al fijarla, el resultado deja de depender de ese dato.
  static Future<void> inicializar(CameraController controller) async {
    await controller.initialize();
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (e) {
      debugPrint('[camara] no se pudo fijar la orientación: $e');
    }
  }

  /// Pide enfoque y exposición sobre un punto del encuadre, en coordenadas
  /// normalizadas (0,0 = esquina superior izquierda; 1,1 = inferior derecha).
  ///
  /// Devuelve false si el equipo no lo admite. Las terminales de control de
  /// acceso suelen traer lente de foco fijo, calibrada para rostros a medio
  /// metro: ahí no hay arreglo por software y el documento tiene que
  /// acercarse o alejarse hasta caer en ese plano.
  static Future<bool> enfocarEn(
    CameraController controller,
    Offset punto,
  ) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(punto);
      await controller.setExposurePoint(punto);
      return true;
    } catch (e) {
      debugPrint("[camara] el equipo no admite enfoque dirigido: $e");
      return false;
    }
  }

  /// Controlador ya configurado para este hardware.
  static CameraController controlador(
    CameraDescription camara,
    ResolutionPreset resolucion,
  ) {
    return CameraController(camara, resolucion, enableAudio: false);
  }
}
