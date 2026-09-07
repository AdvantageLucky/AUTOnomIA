# ADR-0021: Asistente de voz push-to-talk (STT/TTS), nunca escucha continua

**Estado:** Aceptado
**Fecha:** 2026-08-29
**Relacionado:** ADR-0007 (destinos con titular para verificación STT)

## Contexto

ADR-0007 ya había anticipado que el dominio de destinos necesitaría soportar verificación hablada,
pero hasta ahora el kiosko no tenía ningún mecanismo real de entrada por voz: el visitante que no
sabe leer bien, no encuentra su destino en la lista, o simplemente prefiere hablar, no tenía más
opción que el teclado en pantalla. Faltaba decidir cómo capturar voz sin comprometer la privacidad
(un kiosko escuchando todo el tiempo en un espacio público es inaceptable) ni bloquear el flujo si el
reconocimiento de voz del dispositivo falla o no está instalado.

## Decisión

1. **`AsistenteServicio`** (`core/services/asistente_servicio.dart`) envuelve `speech_to_text` en
   modo **push-to-talk exclusivamente**: nunca hay escucha continua ni activación por palabra clave.
   La escucha empieza cuando el visitante mantiene presionado un botón y termina de dos formas —
   soltarlo (caso normal, llama `detener()`) o un límite duro de 15 segundos
   (`SpeechListenOptions(listenFor: ...)`) como red de seguridad. Un timeout adicional (15s + 5s)
   protege contra un cuelgue del propio plugin STT.

2. **Dos modos de uso de la misma transcripción, según `tipoCampo`:**
   - `tipoCampo == null` → pregunta libre: la transcripción se manda a `KioskoServicio
     .preguntarAsistente`, la respuesta se narra por TTS (`TextToSpeakServicio`) y también se
     regresa como texto — el ícono vuelve a "inactivo" de inmediato sin esperar a que termine de
     hablar, para no dejar la UI bloqueada durante todo el TTS.
   - `tipoCampo == 'placa' | 'destino'` → extracción de campo: la transcripción se manda a
     `KioskoServicio.extraerCampoAsistente`, silenciosa (sin TTS), y el resultado
     (`CampoExtraido`) llena un campo del formulario en vez de responder una pregunta.

3. **`AsistenteServicio` nunca dispara acciones ni navega.** Solo entrega el resultado al caller vía
   callbacks (`onRespuestaLibre`, `onCampoExtraido`, `onNoEntendido`) — la decisión de qué hacer con
   ese resultado (llenar un campo, avanzar de paso) vive en cada pantalla que lo usa.

4. **El asistente visual (mascota/micrófono/vigilante) es un componente separado** que solo
   coordina cuándo puede hablar (`AsistenteController.decir`) para no interrumpir una interacción del
   usuario en curso — esa decisión vive en el propio botón (`BotonAsistente`), no en
   `AsistenteServicio`.

## Consecuencias

Positivas:
- Ningún micrófono queda abierto sin que el visitante lo pida explícitamente — descarta de raíz la
  preocupación de un kiosko "escuchando" en un espacio público.
- El límite duro de 15s (más el timeout de red de seguridad) garantiza que un fallo del plugin STT
  nunca deja el botón atorado en "procesando" indefinidamente.
- Preguntas libres y extracción de campos comparten el mismo pipeline de captura de voz; solo diverge
  el destino de la transcripción.

Negativas / Trade-offs:
- **Depende de que el dispositivo tenga instalado un servicio de reconocimiento de voz del sistema**
  ("Speech Services by Google" u otro) — el hardware Telpo F10 no lo trae de fábrica, hay que
  instalarlo aparte desde la Play Store en cada kiosko nuevo. Sin ese servicio, `iniciar()` falla y
  la función de voz simplemente no está disponible.
- El corte a los 15 segundos puede interrumpir a alguien que todavía no termina de hablar; no hay
  forma de extenderlo desde la UI.
- La calidad de la extracción de campo depende enteramente de lo que el backend interprete de la
  transcripción — un ruido de fondo o un acento no reconocido por el STT del sistema nunca llega
  siquiera a esa etapa.
