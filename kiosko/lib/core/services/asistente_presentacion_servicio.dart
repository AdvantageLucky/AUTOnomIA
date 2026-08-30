/// Rastrea si la mascota-asistente ya se presentó verbalmente
/// ("Hola, soy tu asistente...") durante esta sesión del kiosko. Se
/// presenta una sola vez -- repetirlo en cada pantalla/visitante sería
/// repetitivo; el resto de las apariciones solo mantienen el refuerzo
/// visual (anima al hablar) y textual (etiqueta fija junto a la mascota).
///
/// Estado a nivel de clase, no de instancia -- mismo patrón que
/// `ConsentimientoServicio`: es una bandera de la sesión del kiosko, no de
/// una pantalla en particular. A diferencia de `ConsentimientoServicio`,
/// esta NO se reinicia por visitante -- solo al reiniciar la app.
class AsistentePresentacionServicio {
  static bool _yaPresentado = false;

  static bool get yaPresentado => _yaPresentado;

  static void marcarPresentado() => _yaPresentado = true;
}
