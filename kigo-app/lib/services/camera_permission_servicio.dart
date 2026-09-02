import 'package:permission_handler/permission_handler.dart';

/// El teléfono del residente (a diferencia del kiosko, provisionado con
/// permisos ya concedidos) sí puede negar la cámara -- una vez, o
/// permanentemente ("no volver a preguntar"). Sin esto, `CameraController
/// .initialize()` solo tronaba con un error genérico que no le decía al
/// usuario qué pasó ni cómo arreglarlo.
enum ResultadoPermisoCamara { concedido, denegado, denegadoPermanente }

Future<ResultadoPermisoCamara> solicitarPermisoCamara() async {
  var status = await Permission.camera.status;
  if (status.isGranted) return ResultadoPermisoCamara.concedido;

  status = await Permission.camera.request();
  if (status.isGranted) return ResultadoPermisoCamara.concedido;
  if (status.isPermanentlyDenied || status.isRestricted) {
    return ResultadoPermisoCamara.denegadoPermanente;
  }
  return ResultadoPermisoCamara.denegado;
}
