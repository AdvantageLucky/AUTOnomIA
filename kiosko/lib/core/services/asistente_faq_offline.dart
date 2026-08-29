/// Preguntas frecuentes fijas para cuando el kiosko está sin conexión y no
/// hay LLM disponible — sin esto, el visitante quedaría sin ninguna
/// respuesta posible al presionar el asistente sin internet. Texto
/// hardcodeado a propósito: la versión configurable por el admin es un
/// ítem de roadmap aparte, todavía no construido.
class PreguntaFrecuenteOffline {
  final String pregunta;
  final String respuesta;

  const PreguntaFrecuenteOffline({required this.pregunta, required this.respuesta});
}

const List<PreguntaFrecuenteOffline> preguntasFrecuentesOffline = [
  PreguntaFrecuenteOffline(
    pregunta: '¿Qué documentos necesito?',
    respuesta: 'Necesitas tu identificación oficial (INE) vigente y una foto de tu rostro.',
  ),
  PreguntaFrecuenteOffline(
    pregunta: '¿Cuánto tarda el registro?',
    respuesta: 'El registro toma solo unos minutos: escaneas tu INE, tomas una foto y eliges tu destino.',
  ),
  PreguntaFrecuenteOffline(
    pregunta: '¿Qué es este lugar?',
    respuesta: 'Este es el kiosko de autorregistro de visitantes del fraccionamiento. Aquí puedes registrarte como visitante o acceder si ya eres residente.',
  ),
  PreguntaFrecuenteOffline(
    pregunta: '¿Cómo funciona el registro?',
    respuesta: 'Toca "Visitante" en la pantalla de inicio, sigue los pasos en orden y espera a que el residente que visitas apruebe tu entrada.',
  ),
];
