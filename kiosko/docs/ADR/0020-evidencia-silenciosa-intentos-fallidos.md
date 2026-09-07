# ADR-0020: Captura silenciosa de evidencia en intentos fallidos de PIN/QR

**Estado:** Aceptado
**Fecha:** 2026-09-04
**Relacionado:** ADR-0006 (MLKit face detection local), ADR-0016 (huella facial on-device)

## Contexto

Un PIN de residente incorrecto o un QR de invitación inválido son, hoy, solo un mensaje de error en
pantalla — no queda ningún rastro de quién lo intentó. Frente a un intento malicioso repetido (probar
PINes al azar, reutilizar un QR ya revocado) el equipo de seguridad no tenía ninguna evidencia que
revisar después del hecho, y tampoco forma de saber si varios intentos fallidos en distintos kioskos
correspondían a la misma persona.

## Decisión

1. **`EvidenciaSeguridadServicio.capturar()`** (`core/services/evidencia_seguridad_servicio.dart`)
   toma una foto en segundo plano —sin vista previa, sin que la persona lo note— y calcula su huella
   facial con el mismo `ReconocimientoFacialServicio` de ADR-0016, **después** de que la pantalla de
   error ya se decidió mostrar. Se dispara desde `resident_pin_viewmodel.dart` (PIN incorrecto) y
   `qr_result_viewmodel.dart` (QR inválido), que mandan foto + embedding a
   `KioskoServicio.reportarEventoSeguridad`.

2. **Nunca bloquea ni falla visiblemente.** Cámara ocupada por otra pantalla, ausencia de hardware de
   cámara, o ningún rostro en cuadro: todo se traga dentro del servicio y regresa `(pathFoto: null,
   embedding: null)` como resultado válido, no como error. El flujo de PIN/QR continúa exactamente
   igual con o sin evidencia.

3. **La correlación facial ocurre del lado del backend**, no en el kiosko — el kiosko solo adjunta
   foto y embedding al evento; cruzar varios eventos fallidos contra el mismo rostro es
   responsabilidad del backend de Seguridad.

## Consecuencias

Positivas:
- Un intento de PIN/QR fallido deja de ser invisible: hay foto y huella facial disponibles para
  Seguridad, correlacionables entre kioskos e intentos.
- No introduce ningún riesgo nuevo de bloquear la UI: el flujo normal de error no cambia su
  comportamiento aunque la captura falle por completo.

Negativas / Trade-offs:
- **Es una captura biométrica sin consentimiento explícito de quien falla el PIN/QR** —a diferencia
  de ADR-0007 (consentimiento de cámara) y ADR-0016 (aviso de privacidad para el acceso por rostro),
  aquí no hay ningún diálogo ni aviso: la persona nunca sabe que se tomó una foto suya. Se acepta
  como excepción de seguridad (evento de posible abuso), pero es una asimetría deliberada frente al
  resto del proyecto que debe revisarse con criterio legal antes de cualquier despliegue fuera de un
  prototipo.
- La foto se toma con la cámara del kiosko, que puede estar orientada al visitante o no según el
  layout de cada pantalla — no hay garantía de que capture un rostro útil.
- Depende de que la cámara esté libre en ese instante; si otra pantalla la tiene abierta, la captura
  simplemente no ocurre y el evento se reporta sin evidencia.
