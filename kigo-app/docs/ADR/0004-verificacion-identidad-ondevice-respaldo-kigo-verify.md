# ADR-0004: Verificación de identidad on-device, con Kigo Verify como respaldo tras fallos repetidos

**Estado:** Aceptado
**Fecha:** 2026-08-29
**Relacionado:** ADR-0003 (identidad Persona), kiosko ADR-0016 (huella facial on-device), backend
ADR-0032 (Kigo Verify como proveedor externo de liveness)

## Contexto

El wizard de identidad (ADR-0003) necesita un INE escaneado y una foto de rostro con su embedding
facial. El camino por defecto —cámara propia del teléfono, OCR y detección de rostro on-device— no
siempre completa: cámaras frontales de gama baja, mala luz, o una persona que después de varios
intentos no logra que `google_mlkit_face_detection` confirme un rostro válido. Sin alternativa, esas
personas quedaban bloqueadas sin poder terminar su alta. Kigo Verify —el mismo proveedor externo de
verificación con liveness check documentado en backend ADR-0032— ofrece una vía alterna vía WebView,
pero traía el riesgo de generar una dependencia de red y de UI mucho más compleja si se volvía el
camino principal.

## Decisión

1. **El camino por defecto sigue siendo 100% on-device.** `StepEscanearIne` corre
   `google_mlkit_text_recognition` sobre la INE; `StepEscanearRostro` activa la cámara frontal, hace
   sondeo periódico (cada 700ms) con `FaceDetectorServicio` (ML Kit, liviano) y solo calcula el
   embedding pesado (`ReconocimientoFacialServicio`, MobileFaceNet vía `tflite_flutter` — mismo
   modelo `.tflite` que usa el kiosko, ver kiosko ADR-0016) una vez, sobre la foto ya confirmada por
   2 detecciones consecutivas.

2. **"Verificar con Kigo" es un botón secundario, siempre visible junto al de cámara**, que delega el
   paso de rostro a Kigo Verify: pide un `enrollment` al backend
   (`KigoVerifyServicio.iniciar`, backend ADR-0032), abre su `enrollmentUrl` en un WebView de
   pantalla completa, hace polling de estado (cada 3s, límite duro de 3 minutos) hasta `COMPLETED` o
   `FAILED`, descarga la foto resultante y le calcula el embedding **localmente**, con el mismo
   `ReconocimientoFacialServicio` — Kigo Verify sustituye la *captura* del rostro, nunca el cómputo
   de la huella, que sigue siendo responsabilidad exclusiva del cliente.

3. **El botón desaparece tras 5 intentos fallidos de Kigo Verify en ese mismo paso**
   (`_maxIntentosKigo = 5`), forzando de vuelta el camino manual con la cámara propia — evita un
   ciclo infinito de reintentos contra un servicio externo que, para esa persona o ese dispositivo,
   no está funcionando.

## Consecuencias

Positivas:
- Nadie queda completamente bloqueado en el paso de rostro: hay dos caminos independientes para
  llegar al mismo resultado (foto + embedding).
- El embedding siempre se calcula en el dispositivo, sin importar el origen de la foto — el criterio
  de privacidad ("la imagen no sale sin que el cliente ya tenga su huella") es uniforme entre ambos
  caminos.
- Reutilizar `ReconocimientoFacialServicio` para ambos caminos evita mantener dos formatos de
  embedding que después no calzarían al compararse en el backend.

Negativas / Trade-offs:
- El flujo de Kigo Verify agrega una dependencia de red externa (WebView + polling con límite de 3
  minutos) que el camino con cámara propia no tiene — una persona que use "Verificar con Kigo" con
  mala conexión puede esperar minutos sin resultado.
- El límite de 5 intentos fallidos es un valor fijo en el cliente, sin telemetría que confirme si es
  demasiado generoso o demasiado estricto en la práctica.
- Dos caminos independientes para el mismo dato duplican la superficie de pruebas y de errores
  posibles (cámara propia vs. WebView + descarga + reintento) para un solo paso del wizard.
