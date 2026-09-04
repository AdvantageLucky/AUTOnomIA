/// Formateo de fechas para la UI.
///
/// El backend corre con el reloj en UTC y serializa los `time.Time` con la Z
/// al final, asi que `DateTime.parse` sobre cualquier `created_at` /
/// `expires_at` devuelve un DateTime con `isUtc = true`. Leer `.day` o
/// `.hour` de ese objeto da la hora UTC, no la del usuario: una invitacion
/// creada a las 20:00 en Mexico (UTC-6) se guarda como las 02:00 del dia
/// siguiente y la pantalla mostraba esa fecha corrida un dia.
///
/// De ahi que estas funciones hagan siempre `toLocal()` primero. La misma
/// linea estaba repetida a mano en cada vista y era justo donde se olvidaba,
/// por eso vive aqui.
///
/// Ojo: solo hay que pasar por aqui las fechas que vienen del backend. Una
/// fecha que ya nacio local — la que devuelve `showDatePicker`, por ejemplo —
/// no necesita conversion, y aplicarsela igual seria inofensivo pero
/// engañoso al leer el codigo.
library;

/// `dd/mm/aaaa` en la zona del dispositivo.
String fechaCortaLocal(DateTime fecha) {
  final d = fecha.toLocal();
  return '${d.day}/${d.month}/${d.year}';
}
