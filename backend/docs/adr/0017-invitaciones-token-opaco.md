# ADR-0017: Invitaciones con token opaco generado por el servidor

**Estado:** Aceptado  
**Fecha:** 2026-07-30

## Contexto

Los residentes necesitan poder invitar a visitantes (personas o grupos) de antemano, para que el kiosko los pueda identificar y reducir la fricción de entrada. Se evaluaron dos enfoques para el token:

- **JWT firmado por el residente**: incluiría los datos del invitado en el payload y sería auto-contenido.
- **Token opaco generado por el servidor**: semilla aleatoria que apunta a un registro en la BD.

## Decisión

Se usa un **token opaco**: 32 bytes de `crypto/rand` codificados en hex (64 caracteres). El servidor lo genera al crear la invitación y es la única vez que viaja al cliente.

### Por qué no JWT

Los JWT no se pueden revocar sin una lista de revocación. Un residente que crea una invitación equivocada, o quiere cancelarla antes de que llegue el visitante, necesita poder invalidarla inmediatamente. Con token opaco, el soft-delete en la tabla equivale a revocación instantánea: el kiosko llama `FindByToken` y la fila ya no existe.

### Modelo

```go
type Invitacion struct {
    gorm.Model              // DeletedAt = revocada
    Token       string      // hex 64 chars, uniqueIndex
    Tipo        TipoInvitacion  // PERSONAL | GRUPAL
    Titular     string      // nombre del invitado (PERSONAL) o identificador del grupo (GRUPAL)
    ResidenteID uint
    DestinoID   uint
    ConteoUsos  int         // cuántas veces se ha usado
    MaxUsos     *int        // nil = sin límite
    ExpiresAt   *time.Time  // nil = sin expiración
}
```

`PERSONAL` vs `GRUPAL` no cambia la validación del token: ambos usan el mismo flujo. La diferencia está en el `Titular` — en `PERSONAL` es el nombre de la persona; en `GRUPAL` es un identificador del grupo (p. ej. "Familia García").

### Flujo

```
Residente  →  POST /residentes/me/invitaciones  →  recibe token (una sola vez)
Residente  →  genera QR con el token en la app
Visitante  →  presenta QR en el kiosko
Kiosko     →  GET /kioskos/:id/invitaciones/validar?token=XXX  →  datos para pre-llenar visita
Kiosko     →  POST /kioskos/:id/visitas  (TipoVisitante=INVITADO, campos pre-llenados)
Kiosko     →  POST /kioskos/:id/invitaciones/:token/usar  →  incrementa ConteoUsos
```

El `validar` es de solo lectura; el `usar` tiene los efectos secundarios (incremento + auto-revocación si `ConteoUsos >= MaxUsos`). Esta separación permite al kiosko mostrar la pantalla de confirmación antes de comprometer el uso.

### Reglas de validez (FindByToken)

1. Fila existe y `deleted_at` es null (no revocada)
2. `expires_at` es null **o** está en el futuro
3. `max_usos` es null **o** `conteo_usos < max_usos`

### Auto-revocación

`IncrementarUso` corre en transacción: incrementa `conteo_usos` y, si llega a `max_usos`, hace soft-delete en la misma transacción. Así una invitación de un solo uso queda revocada atómicamente después de usarse, sin necesidad de un job de limpieza.

## Consecuencias

- La revocación es inmediata y no requiere lista negra.
- El token no contiene información: si la BD cae, el kiosko no puede validar offline (aceptable para FEPRO; el modo offline es una mejora futura).
- El QR que genera la app residente puede ser estático (solo el token en texto plano o URI) — la app no necesita lógica de firma.
- `max_usos = nil` permite invitaciones permanentes (p. ej. empleados domésticos recurrentes), útil para el escenario de fraccionamiento.
