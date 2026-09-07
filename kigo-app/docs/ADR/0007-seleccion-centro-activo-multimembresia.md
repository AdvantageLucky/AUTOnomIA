# ADR-0007: Selección de centro activo, persistida, para el escenario multi-membresía

**Estado:** Aceptado
**Fecha:** 2026-08-24
**Relacionado:** ADR-0003 (identidad Persona + Membresia)

## Contexto

Con la identidad rediseñada alrededor de `Persona` + `Membresia` (ADR-0003), una misma cuenta puede
tener membresías activas en más de un centro habitacional a la vez. Casi toda la app —invitaciones,
solicitudes, historial, compañeros de casa, identidades de confianza— es una operación que solo tiene
sentido **dentro de un centro concreto** (`tenant_id`). Hacía falta decidir contra cuál de las
membresías activas operan esas pantallas cuando hay más de una.

## Decisión

1. **`AuthViewModel` mantiene un `centroActivoId`** resuelto contra la lista de `membresiasActivas`.
   Al cargar membresías (`_cargarMembresias`), si el centro activo previamente persistido
   (`shared_preferences`) sigue entre las membresías activas, se conserva; si no, cae automáticamente
   a la primera membresía activa disponible; si no hay ninguna, queda en `null`.

2. **`setCentroActivo(tenantId)` es la única forma explícita de cambiarlo** — ignora silenciosamente
   un `tenantId` que ya no esté entre las membresías activas (por ejemplo, un botón obsoleto en
   pantalla tras perder esa membresía), en vez de lanzar un error.

3. **Todas las pantallas que dependen del tenant leen `centroActivo`/`centroActivoId` de
   `AuthViewModel`**, no reciben un tenant por parámetro de navegación — cambiar de centro activo
   dispara `notifyListeners()` y las vistas que ya están montadas se refrescan contra el nuevo tenant
   sin necesitar renavegar.

## Consecuencias

Positivas:
- El caso de una sola membresía (el más común) no requiere que la persona elija nada — el fallback
  automático a "la primera activa" hace que la app funcione igual que si no existiera el concepto de
  selección.
- Perder una membresía (rechazo, expulsión) mientras es la activa se resuelve solo, sin dejar la app
  en un estado apuntando a un tenant que ya no aplica.

Negativas / Trade-offs:
- El centro activo es un solo valor global compartido por toda la app — no hay forma de ver datos de
  dos centros simultáneamente (ej. una vista comparativa); cambiar de centro implica que las
  pantallas ya cargadas se refresquen contra el nuevo tenant.
- La persistencia en `shared_preferences` es por instalación de la app, no por `Persona` — si la
  misma cuenta inicia sesión en otro dispositivo, el centro activo se recalcula desde cero (primera
  membresía activa) en vez de recordar la preferencia previa.
