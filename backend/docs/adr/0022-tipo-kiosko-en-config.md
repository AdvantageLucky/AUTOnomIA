# ADR-0022: El tipo de kiosko viaja en su configuración

**Estado:** Aceptado
**Fecha:** 2026-08-13
**Extiende:** ADR-0011 (configuración parametrizable por kiosko)

## Contexto

La columna `kioskos.tipo` (`PEATONAL` | `VEHICULAR`, migración 000020) existía
desde antes junto con los toggles `foto_placa_visitante` y `foto_placa_invitado`,
y `PatchConfig` ya rechazaba encender esos toggles en un kiosko peatonal. El
dashboard permitía dar de alta un kiosko de cada tipo.

Pero el tipo nunca salía del backend hacia la terminal. La app del kiosko solo
consume `KioskoConfigResponse` —por `GET /kioskos/{id}/config/mia` al arrancar y
después por el stream SSE— y ese DTO no incluía `tipo`. La consecuencia era que
la distinción existía en la base de datos y en el dashboard, pero no cambiaba
nada del comportamiento de la terminal: un kiosko marcado como vehicular corría
exactamente el mismo flujo peatonal.

Las alternativas para que la app supiera su tipo eran:

1. Un endpoint aparte que la app consultara al arrancar.
2. Un build/flavor distinto por tipo de acceso.
3. Incluir el tipo en la config que la app ya consume.

## Decisión

**El tipo viaja como un campo más de `KioskoConfigResponse`.**

```go
type KioskoConfigResponse struct {
    KioskoID uint       `json:"kiosko_id"`
    Tipo     TipoKiosko `json:"tipo"`
    // ...
}
```

`Tipo` pertenece al modelo `Kiosko`, no a `KioskoConfig`, así que
`toKioskoConfigResponse` lo recibe como parámetro aparte y cada handler lo
resuelve: `GetConfig` y `PatchConfig` ya tenían el kiosko en scope,
`GetConfigDesdeKiosko` hace un `FindByID` adicional.

Se descartó el endpoint aparte (opción 1) porque duplicaría el canal de
sincronización: la config ya se transmite por SSE y el tipo tendría que
enterarse por otra vía. Se descartaron los flavors (opción 2) porque obligarían
a reinstalar la app para cambiar una caseta de peatonal a vehicular, cuando el
kiosko ya se activa contra el backend (ADR-0019) y recibe su configuración
remota.

**Consecuencia directa: cambiar el tipo desde el dashboard reconfigura la
terminal en vivo.** `PatchKiosko` ahora emite la config por el mismo hub SSE
cuando el tipo cambió, y al pasar un kiosko a peatonal apaga los toggles de
placa —que `PatchConfig` ya prohibía para ese tipo y que el flujo peatonal no
tiene forma de cumplir—, evitando que la terminal quede con una config que hace
fallar todos sus registros con 400.

## Consecuencias

- Un solo APK sirve para casetas peatonales y vehiculares; quién es cada tablet
  lo decide el admin desde el dashboard, no quien la instala.
- La app puede seguir arrancando contra un backend viejo que no mande `tipo`:
  el default del lado del cliente es `PEATONAL`, el flujo que no exige capturas
  que la terminal quizá no pueda tomar.
- El DTO de config deja de ser un espejo exacto de la tabla `kiosko_configs`.
  Se acepta el costo: el DTO es lo que la app necesita para operar, no un
  reflejo del esquema.
- Si un admin cambia el tipo mientras alguien está a media captura, esa sesión
  se pierde al reconstruirse el árbol de widgets. Es una operación rarísima
  (una caseta no cambia de naturaleza a media fila) y el precio es que la
  reconfiguración no necesita reiniciar la terminal.
