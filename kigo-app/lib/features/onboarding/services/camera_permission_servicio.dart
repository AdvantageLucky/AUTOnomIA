import 'package:permission_handler/permission_handler.dart';

/// El teléfono del residente (a diferencia del kiosko, provisionado con
/// permisos ya concedidos) sí puede negar la cámara -- una vez, o
/// permanentemente ("no volver a preguntar"). Sin esto, `CameraController
/// .initialize()` solo tronaba con un error genérico que no le decía al
/// usuario qué pasó ni cómo arreglarlo.
enum ResultadoPermisoCamara { concedido, denegado, denegadoPermanente }

/// Timeout de red de seguridad para `Permission.camera.request()`. En
/// algunos Android, si el request se dispara mientras todavía hay una
/// transición de ventana en curso (p.ej. justo tras cerrar el teclado del
/// OTP), el canal de plataforma nunca entrega la respuesta y el Future se
/// queda colgado para siempre -- sin esto, la pantalla que espera este
/// resultado se quedaba en su spinner de carga sin llegar siquiera a
/// mostrar el diálogo nativo de permiso.
const _timeoutSolicitudPermiso = Duration(seconds: 10);

Future<ResultadoPermisoCamara> solicitarPermisoCamara() async {
  var status = await Permission.camera.status;
  if (status.isGranted) return ResultadoPermisoCamara.concedido;

  try {
    status = await Permission.camera.request().timeout(_timeoutSolicitudPermiso);
  } on Exception {
    // Timeout u otro error del canal de plataforma -- se trata como
    // denegado (no permanente) para que la pantalla ofrezca reintentar en
    // vez de quedarse cargando para siempre.
    return ResultadoPermisoCamara.denegado;
  }
  if (status.isGranted) return ResultadoPermisoCamara.concedido;
  if (status.isPermanentlyDenied || status.isRestricted) {
    return ResultadoPermisoCamara.denegadoPermanente;
  }
  return ResultadoPermisoCamara.denegado;
}
