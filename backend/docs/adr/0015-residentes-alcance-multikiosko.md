# ADR-0015: Alcance de residentes en escenario multi-kiosko

**Estado:** Aceptado  
**Fecha:** 2026-07-17

## Contexto

El modelo actual tiene `Residente.KioskoID` — el residente está ligado a un kiosko específico. En un desarrollo con múltiples entradas (ej. Infonavit con kiosko A en entrada norte, kiosko B en entrada sur, kiosko C en estacionamiento), un residente del Depto 202 debe poder recibir visitas que lleguen por **cualquier** entrada, no solo la que tiene asignada.

Con el modelo actual, si el residente tiene `KioskoID = 1` (Kiosko A) y un visitante llega por el Kiosko B, la búsqueda `WHERE casa_destino = 'Depto 202' AND kiosko_id = 2` no encuentra al residente y la solicitud queda huérfana.

## Decisión

Cambiar `Residente.KioskoID` por `Residente.AdminID`. El residente pertenece a la **comunidad administrada por el admin**, no a una entrada específica.

### Impacto en búsqueda de residente desde el kiosko

Al recibir una visita, el kiosko conoce su `KioskoID`. Cada `Kiosko` tiene un `AdminID`. La búsqueda de residente cambia de:

```sql
-- Antes
WHERE casa_destino = ? AND kiosko_id = ?
-- Después
WHERE casa_destino = ? AND admin_id = (SELECT admin_id FROM kioskos WHERE id = ?)
```

### Impacto en la app de residente

El residente se autentica con su PIN. El JWT del residente incluye `admin_id` en lugar de `kiosko_id`. La app recibe notificaciones de solicitudes de **cualquier kiosko del admin**, filtradas por `casa_destino` del residente.

El residente no necesita saber qué kiosko usó el visitante — solo importa que es alguien que llega a su casa.

### Migración

```sql
ALTER TABLE residentes ADD COLUMN admin_id bigint REFERENCES admins(id);
UPDATE residentes r SET admin_id = a.admin_id FROM kioskos a WHERE a.id = r.kiosko_id;
ALTER TABLE residentes ALTER COLUMN admin_id SET NOT NULL;
ALTER TABLE residentes DROP COLUMN kiosko_id;
```

## Consecuencias

- Un residente que antes estaba limitado a un kiosko ahora recibe notificaciones de todos los kioskos del admin. Esto es el comportamiento correcto.
- El dashboard de admin puede gestionar todos los residentes de la comunidad sin filtrar por kiosko.
- La app de residente no necesita reconfigurarse al añadir nuevos kioskos al admin.
- Requiere migración de datos y actualización del JWT de residente (cambiar claim `kiosko_id` → `admin_id`).
