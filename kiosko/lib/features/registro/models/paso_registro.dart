/// Un paso del pipeline de registro, en el orden que el admin arrastró en el
/// dashboard (`pasos_sin_invitacion`).
///
/// Antes sólo INE y ROSTRO eran pasos de verdad: DESTINO estaba clavado
/// después de todas las capturas y PLACA se resolvía en paralelo desde el
/// constructor del viewmodel, así que su posición en la lista no cambiaba
/// nada. Arrastrar DESTINO al primer lugar en el dashboard no tenía ningún
/// efecto visible en el kiosko.
enum PasoRegistro {
  /// Captura de INE con OCR. La dispara el botón de la pantalla.
  ine,

  /// Captura de rostro. La dispara el botón de la pantalla.
  rostro,

  /// Lectura/confirmación de placa. Sólo en el flujo vehicular; la lectura
  /// arranca en paralelo al crearse el viewmodel y aquí sólo se confirma.
  placa,

  /// Elegir a qué casa va. Empuja CasaDestinoView.
  destino,

  /// Por qué viene el visitante. Empuja MotivoView. Solo aplica a quien
  /// llega sin invitación -- un invitado ya trae el motivo desde la
  /// invitación que lo creó, así que este paso nunca se habilita para él
  /// (ver `habilitados` en los viewmodels).
  motivo,
}

/// true si el paso se resuelve solo al llegarle el turno, sin esperar un
/// toque del visitante. INE y ROSTRO necesitan que aprete el botón de la
/// pantalla; DESTINO, PLACA y MOTIVO no tienen nada que encuadrar, así que
/// empujan su pantalla de una vez — es el comportamiento que DESTINO ya
/// tenía cuando estaba clavado al final.
bool esPasoAutomatico(PasoRegistro paso) =>
    paso == PasoRegistro.destino ||
    paso == PasoRegistro.placa ||
    paso == PasoRegistro.motivo;

const _tokenPorPaso = {
  'INE': PasoRegistro.ine,
  'ROSTRO': PasoRegistro.rostro,
  'PLACA': PasoRegistro.placa,
  'DESTINO': PasoRegistro.destino,
  'MOTIVO': PasoRegistro.motivo,
};

/// Traduce la lista ordenada del dashboard a los pasos que este kiosko va a
/// ejecutar de verdad, respetando el orden y descartando los que su config
/// no pide.
///
/// [orden] son los tokens tal cual vienen del backend. Los que no reconocemos
/// se ignoran en silencio a propósito: el dashboard puede aprender un paso
/// nuevo antes de que el APK del kiosko sepa ejecutarlo, y en ese caso vale
/// más saltárselo que romper el registro.
///
/// [fallback] se usa si no quedó ningún paso — un pipeline vacío dejaría al
/// visitante en una pantalla sin nada que hacer.
List<PasoRegistro> construirPasosOrdenados({
  required List<String> orden,
  required Set<PasoRegistro> habilitados,
  required List<PasoRegistro> fallback,
}) {
  final pasos = <PasoRegistro>[];
  for (final token in orden) {
    final paso = _tokenPorPaso[token.toUpperCase()];
    if (paso == null) continue;
    if (!habilitados.contains(paso)) continue;
    if (pasos.contains(paso)) continue; // el dashboard no debería repetir, pero por si acaso
    pasos.add(paso);
  }

  // Un paso habilitado que el dashboard no listó se agrega al final en vez de
  // perderse: la config dice que hace falta, y el orden es una preferencia.
  for (final paso in habilitados) {
    if (!pasos.contains(paso)) pasos.add(paso);
  }

  return pasos.isEmpty ? fallback : pasos;
}
