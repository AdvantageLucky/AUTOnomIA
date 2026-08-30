/// Rastrea si el visitante actual ya dio el consentimiento de uso de datos
/// durante esta visita. `QrScannerView` (pantalla de entrada, la única por
/// la que pasa el 100% de los visitantes, con QR o sin QR) es quien lo pide
/// y lo marca; las pantallas de captura (INE, rostro) lo consultan para no
/// volver a pedirlo en la misma visita — antes se pedía hasta 3 veces por
/// visitante, uno de los motivos de fricción reportados.
///
/// Estado a nivel de clase (no instancia): el consentimiento es del
/// visitante actual, no de una pantalla en particular, y varias pantallas
/// necesitan leerlo sin compartir una instancia inyectada.
class ConsentimientoServicio {
  static bool _otorgado = false;

  static bool get otorgado => _otorgado;

  /// Se llama solo desde la pantalla de entrada, tras aceptar el diálogo.
  static void otorgar() => _otorgado = true;

  /// Nueva visita: el consentimiento de la persona anterior no aplica al
  /// siguiente visitante. Se llama al mostrar de nuevo la pantalla de
  /// entrada (`QrScannerView`), antes de decidir si hay que preguntar.
  static void reiniciar() => _otorgado = false;
}
