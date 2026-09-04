import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:kigo_kiosco/core/services/camara_kiosko.dart';
import 'package:kigo_kiosco/features/residente/services/reconocimiento_facial_servicio.dart';

/// Resultado de un intento de captura silenciosa -- ambos campos nulos es un
/// resultado válido (no rompe el flujo de PIN/QR, solo se reporta sin
/// evidencia), no un error.
typedef EvidenciaFallida = ({String? pathFoto, List<double>? embedding});

/// Captura una foto en segundo plano (sin vista previa, sin que el
/// residente/visitante lo note) y calcula su huella facial, para adjuntarla
/// a un evento de seguridad (PIN incorrecto, QR inválido) -- ver
/// KioskoServicio.reportarEventoSeguridad.
///
/// Esto corre DESPUÉS de que la pantalla de error ya se decidió mostrar, así
/// que nunca debe bloquear ni fallar visiblemente: cualquier problema (la
/// cámara ocupada por otra pantalla, sin rostro en cuadro, hardware sin
/// cámara) se traga aquí mismo y regresa ambos campos en null.
class EvidenciaSeguridadServicio {
  static final ReconocimientoFacialServicio _huellaFacialServicio =
      ReconocimientoFacialServicio();

  static Future<EvidenciaFallida> capturar() async {
    CameraController? controller;
    try {
      final camara = await CamaraKiosko.paraRostro();
      controller = CamaraKiosko.controlador(camara, AjustesCamara.resolucionRostro);
      await CamaraKiosko.inicializar(controller);
      final foto = await controller.takePicture();
      final embedding = await _huellaFacialServicio.calcularEmbedding(foto.path);
      return (pathFoto: foto.path, embedding: embedding);
    } catch (e) {
      debugPrint('[evidencia-seguridad] no se pudo capturar: $e');
      return (pathFoto: null, embedding: null);
    } finally {
      await controller?.dispose();
    }
  }
}
