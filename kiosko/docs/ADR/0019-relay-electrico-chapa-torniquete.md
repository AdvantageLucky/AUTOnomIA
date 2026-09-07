# ADR-0019: Apertura del relay eléctrico de la chapa/torniquete al aprobar el acceso

**Estado:** Aceptado
**Fecha:** 2026-09-02
**Autores:** (completar)

## Contexto

Hasta ahora, una visita aprobada solo cambiaba de color en pantalla (`LedServicio`) — abrir la
puerta o la pluma física seguía dependiendo de un humano (el vigilante, viendo la pantalla). El
hardware Telpo F10 sobre el que corre el kiosko expone un relay eléctrico controlable por software
(`PosUtil.setRelayPower`, documentado en `F10SDK/doc/Telpo F10SDK Manual.docx`, sección Relay), capaz
de accionar la chapa de una puerta peatonal o la pluma de un torniquete/vehicular, y hasta este punto
nadie lo invocaba.

## Decisión

1. **`RelayServicio`** (`core/services/relay_servicio.dart`) envuelve el canal nativo
   (`MethodChannel('com.example.kigo_kiosco/relay')`) con un único método: `abrir({segundos: 4})`.
   Cuatro segundos es el tiempo por defecto estimado para que pase un peatón o un vehículo; el
   cierre se agenda del lado nativo (Android), así que ocurre aunque la pantalla Flutter que lo pidió
   ya no exista.

2. **Se llama desde cada punto donde una visita ya quedó aprobada**, no desde un lugar centralizado:
   `persona_qr_result_view.dart`, `qr_result_view.dart`, `resumen_solicitud_view.dart` y
   `resident_welcome_view.dart` instancian su propio `RelayServicio` y llaman `abrir()` en el momento
   en que la pantalla de éxito se muestra. No existe un middleware o un punto único de "acceso
   concedido" que lo dispare por todos.

3. **Falla silenciosa, igual que `LedServicio`.** Un kiosko puede no tener el relay cableado todavía
   —otro modelo de hardware, un emulador, un torniquete pendiente de instalar— y eso nunca debe
   tronar ni siquiera mostrarse en la pantalla de resultado. Cualquier `PlatformException` u otro
   error se traga dentro de `RelayServicio`.

## Consecuencias

Positivas:
- El acceso aprobado por el kiosko ahora puede abrir la puerta/pluma físicamente, sin depender de que
  un vigilante esté mirando la pantalla en ese instante.
- Un kiosko sin el relay cableado sigue funcionando exactamente igual que antes — la falla es
  invisible por diseño.

Negativas / Trade-offs:
- **No hay un solo lugar que "conceda acceso".** Cada vista de éxito nueva que se agregue tiene que
  acordarse de instanciar `RelayServicio` y llamar `abrir()` por su cuenta; olvidarlo no produce
  ningún error, solo una puerta que nunca se abre — un bug silencioso por construcción, coherente con
  el resto del servicio pero peligroso de diagnosticar en campo.
- No hay confirmación de que el relay físicamente respondió (no es un circuito con retroalimentación)
  — el kiosko no puede distinguir "la chapa abrió" de "el cable no está conectado".
- El tiempo fijo de 4 segundos es el mismo para acceso peatonal y vehicular; un vehículo lento podría
  necesitar más tiempo del que la pluma permanece abierta.
