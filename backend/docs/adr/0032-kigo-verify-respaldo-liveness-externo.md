# 0032 - Kigo Verify como proveedor externo de liveness, backend como intermediario

## Status
Accepted

(Relacionado: [0031](0031-persona-membresia-identidad-global.md); ver spec
`2026-08-29-kigo-verify-kigo-app-design.md`)

## Context
La captura de rostro on-device (cámara + MobileFaceNet en kigo-app, mismo modelo que el kiosko) no
siempre completa: cámaras frontales de gama baja, luz insuficiente, o simplemente una persona que no
logra encuadrarse tras varios intentos. Sin una alternativa, esas personas quedaban bloqueadas en el
wizard de identidad sin poder terminar su alta.

Kigo Verify es un servicio externo de verificación de identidad con liveness check (el mismo grupo de
producto que la mini-app Kigo Parkimovil ya referenciada en ADR-0031) accesible por HTTP. Exponerlo
directo desde kigo-app habría significado empaquetar su API key en el APK — extraíble por cualquiera
que lo descompile — y le habría dado a Kigo Verify acceso directo a la sesión de la Persona.

## Decision
El backend actúa como intermediario obligatorio; kigo-app nunca habla directo con Kigo Verify.

- **`POST /personas/me/kigo-verify/iniciar`** crea un `KigoVerifyEnrollment`
  (`kigo_verify_model.go`) — `PersonaID`, `EnrollmentID`, un `WebhookSecret` propio por intento y
  `ExpiresAt` — y le pide a Kigo una URL de enrollment. La API key de Kigo Verify vive solo en la
  configuración del backend.
- **`redirect_url` viaja en la respuesta, no está fija en el cliente.** Es el mismo valor que el
  backend le pidió a Kigo como URL de retorno; si estuviera escrita por separado en las dos puntas
  (backend y kigo-app) podría desincronizarse en silencio y el WebView del cliente no detectaría
  nunca el fin del flujo. El cliente solo compara con lo que el backend le mandó.
- **La app abre `enrollment_url` en un WebView propio de pantalla completa** (no un browser externo,
  para no perder el contexto de la app) y lo cierra cuando la navegación llega a `redirect_url` — el
  resultado real (éxito o falla) no se lee de esa navegación, se resuelve aparte.
- **El estado se resuelve por dos vías que no deben pisarse:** el webhook de Kigo
  (`kigo_verify_handlers.go`) y el polling del cliente (`GET
  /personas/me/kigo-verify/estado?enrollment_id=...`, cada 3s con límite duro de 3 minutos — cubre
  enrollments que Kigo deja atorados en `LIVENESS_STARTED`). `MarcarCompletado` es un
  *compare-and-set* sobre `status <> 'COMPLETED'`: si el webhook y el último poll llegan casi a la
  vez, el que pierde la carrera recibe la URL de foto que ya quedó guardada, nunca la pisa.
- **El backend nunca calcula el embedding.** Cuando el enrollment completa, el backend guarda la
  foto que Kigo entrega (aloja su propia copia) y se la regresa a kigo-app; el cálculo del embedding
  facial sigue siendo responsabilidad exclusiva del cliente, on-device, igual que con la cámara
  propia — Kigo Verify sustituye la *captura*, no el cómputo de la huella.
- **`GET .../estado` está aislado por Persona.** La consulta exige que el `enrollment_id` pertenezca
  a la `Persona` autenticada (`FindByPersonaAndEnrollmentID`); conocer un id ajeno no basta para leer
  su resultado.
- **Es un respaldo, no un reemplazo.** kigo-app decide cuándo ofrecerlo (tras fallos repetidos de la
  cámara propia) y lo retira tras varios intentos fallidos del propio Kigo Verify, forzando de vuelta
  el camino manual — ver ADR de kigo-app sobre verificación de identidad on-device.

## Consequences
- La API key de Kigo Verify nunca sale del backend; revocarla o rotarla no requiere un release de la
  app.
- Cada enrollment tiene su propio `WebhookSecret`, así que un webhook no puede confundirse ni
  falsificarse contra otro intento.
- El flujo depende de que Kigo Verify entregue una foto descargable por URL — si Kigo cambiara ese
  contrato, la ruta de `FotoRostroURL` y la descarga que hace el cliente (`_descargarYGuardarLocal`
  en kigo-app) tendrían que revisarse juntas.
- El límite duro de 3 minutos en el polling significa que un enrollment genuinamente lento (no
  atorado, solo lento) se reporta como fallo al cliente aunque Kigo lo complete después — se acepta
  porque un enrollment normal completa en segundos, no minutos.
- Dos superficies de red nuevas (webhook entrante + polling saliente) para un solo resultado añaden
  complejidad de coordinación (la carrera resuelta por `MarcarCompletado`) que un solo mecanismo no
  tendría — se aceptó a cambio de no depender únicamente del webhook, que puede no dispararse por
  fallos de red efímeros del lado de Kigo.
