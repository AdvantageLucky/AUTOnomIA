# ADR-0022: Asistencia urgente — acción explícita en línea, QR de llamada sin conexión

**Estado:** Aceptado
**Fecha:** 2026-09-02
**Relacionado:** backend ADR-0014 (SSE para tiempo real)

## Contexto

El kiosko necesitaba una vía para que un visitante o residente pida ayuda humana inmediata (una
situación de emergencia o simplemente quedarse atorado en el flujo). La primera versión avisaba al
dashboard/admin automáticamente en cuanto se abría la hoja de asistencia — sin que la persona hiciera
nada más — lo que generaba falsos positivos por curiosidad (abrir la hoja para ver qué es). Además,
el kiosko es una tablet fija sin chip ni app de teléfono real: un botón "llamar" en pantalla no puede
lanzar una llamada de verdad, y sin conexión a internet no hay forma de avisar al backend en absoluto.

## Decisión

1. **Pedir ayuda es una acción explícita, no un efecto de abrir la hoja.** El visitante ve primero un
   resumen de qué va a pasar y debe tocar "Solicitar asistencia" para que el backend avise al
   dashboard/admin — por el mismo canal SSE de backend ADR-0014, más un correo.

2. **Sin internet, degrada a un código QR de `tel:<numero>`** que el visitante escanea **con su
   propio celular**, más el número en texto plano como respaldo. No hay ningún caso en que el kiosko
   intente lanzar una llamada por sí mismo — nunca hay un botón "llamar" en la pantalla del kiosko,
   offline o en línea, porque no hay ningún resultado útil que ese botón pudiera producir en una
   tablet fija sin chip.

3. **El número de contacto es por centro, no por kiosko** (`e53609c`) — así todos los kioskos de una
   misma instalación comparten el mismo contacto de emergencia sin que el admin tenga que
   configurarlo dispositivo por dispositivo.

## Consecuencias

Positivas:
- Se elimina el falso positivo de "abrí la hoja sin querer": ahora hace falta un toque explícito
  sobre "Solicitar asistencia" para que algo le llegue al admin.
- El respaldo offline no depende de que el kiosko tenga capacidad de llamada — la responsabilidad de
  marcar recae en el celular del propio visitante, algo que el kiosko no controla ni necesita tener.

Negativas / Trade-offs:
- Sin internet, el aviso depende por completo de que el visitante tenga su propio celular a la mano y
  decida usarlo — no hay ninguna notificación automática al admin en ese escenario.
- El paso adicional de "confirmar antes de avisar" agrega fricción a una emergencia genuina, a cambio
  de eliminar los falsos positivos — se acepta el trade-off porque el escaneo del QR/marcado directo
  sigue disponible de inmediato como vía paralela sin pasar por el backend.
