# ADR-0026: La placa se lee en paralelo con un punto de integración a hardware, no como paso de la UI

**Estado:** Aceptado
**Fecha:** 2026-08-24
**Extiende:** ADR-0024 (la placa identifica la visita en acceso vehicular)

## Contexto

ADR-0024 estableció que la placa reemplaza a la INE como identificador en un
acceso vehicular, pero no decidió *cómo* se captura. La implementación
original la trataba como un paso más del wizard: pantalla de cámara dedicada
(`EscaneoPlacaPage`), el visitante encuadra la placa y toma la foto, OCR local
con MLKit sobre esa imagen.

Eso es, en la práctica, un simulacro de lo que debería pasar: la placa se lee
con hardware dedicado (cámara IP o lector de placas), aparte de la cámara con
la que el kiosko ve al conductor — nunca debería requerir que el conductor
apunte nada. Ese hardware todavía no existe físicamente. Construir contra él
directamente no era posible; seguir tratando la placa como un paso táctil más
tampoco reflejaba el diseño real, y añadía una pantalla completa (con su
propio desborde de UI, ver commit `6f297a6`) a un flujo que se supone rápido.

## Decisión

**La placa se lee en background, en paralelo con INE/rostro, a través de un
punto de integración reemplazable (`PlacaLectorServicio`) — no es un paso
visible del wizard.**

1. `VehicularRegisterViewModel` arranca la lectura (`_placaLectorServicio.leer()`)
   en su constructor, apenas se crea — en paralelo con los pasos que sí ve el
   conductor. Para cuando termina INE/rostro, la lectura normalmente ya está
   resuelta.
2. `PlacaLectorServicio` es la interfaz — hoy corre `MockPlacaLectorServicio`,
   que siempre resuelve `null` tras una espera. Se decidió **no** simular una
   placa falsa: inventar un valor arriesga que se cuele en un registro real
   durante pruebas de campo. Sustituir la implementación mock por la real es
   el único cambio necesario cuando exista el hardware — nada más del flujo
   se toca.
3. `PasoVehicular` pierde el valor `placa` — ya no es un paso que el
   `StepIndicator` cuente ni que tenga pantalla propia.
4. Sin lectura y si el visitante la necesita (`requierePlaca`: siempre para
   quien no trae invitación, opcional por config si trae invitación), cae al
   teclado manual (`ConfirmarPlacaView`, ya existía) justo antes del resumen —
   el único respaldo, no hay cámara con la que "reintentar".
5. `EscaneoPlacaPage` se borró — sin llamadores tras el cambio.

## Consecuencias

- El flujo vehicular no pierde tiempo con la placa: para el conductor, entre
  bajar la ventanilla y el resumen, la placa ya se resolvió sola o se pide una
  sola vez por teclado.
- `PlacaDetectorServicio` (el OCR de MLKit sobre foto manual, con corrección de
  confusiones de caracteres) se queda sin llamador para su método principal —
  no se borró, solo sus helpers estáticos (`normalizar`/`pareceValida`) siguen
  en uso por el teclado. Si el hardware real termina entregando imágenes en
  vez de texto ya leído, esa lógica se reconecta ahí; si entrega texto
  directo, queda como código muerto pendiente de retirar.
- El diseño da por hecho que el hardware real expondrá una lectura por
  teléfono/consulta (polling a una API local, webhook al backend, etc.) — la
  forma exacta de esa integración es la única pieza que falta y depende del
  proveedor que se elija (ver #48, asistente de voz, y el modo offline, que
  comparten el mismo problema de "no hay conexión con hardware externo
  todavía").
