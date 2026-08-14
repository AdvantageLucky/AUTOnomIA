# ADR-0023: Las capturas del invitado viajan en `UsarInvitacion`

**Estado:** Aceptado
**Fecha:** 2026-08-13
**Extiende:** ADR-0016 (TipoVisitante y validación condicional), ADR-0017 (invitaciones con token opaco)

## Contexto

ADR-0016 definió que los toggles `IneObligatorioInvitado`, `FotoRostroInvitado` y
`FotoPlacaInvitado` deciden qué se le exige a un visitante con invitación, y que
esa validación vive en `validarCamposCondicionales`.

Sin embargo, el único camino por el que un invitado entra al sistema es
`POST /kioskos/{id}/invitaciones/{token}/usar`, que recibía solo el token en la
URL, sin cuerpo. El handler creaba la `Visita` directamente con `Titular`,
`CasaDestino` y estado `APROBADO`, y nunca consultaba la config. Los tres
toggles de invitado eran, en la práctica, inalcanzables: el dashboard los
mostraba y los guardaba, pero ninguna combinación de config hacía que el sistema
pidiera esas capturas. La rama `TipoConInvitacion` de
`validarCamposCondicionales` no la ejecutaba nadie.

Al integrar el flujo vehicular esto dejó de ser teórico: una caseta vehicular
que exige foto de placa a sus invitados no tenía forma de cumplirlo.

Se consideraron tres caminos:

1. **Registrar al invitado por `POST /visitas/`** con `tipo_visitante=INVITADO`,
   dejando `usar` solo para consumir el token.
2. **Un endpoint nuevo** que consumiera la invitación sin crear visita, más el
   registro normal por `/visitas/`.
3. **Extender `UsarInvitacion`** para que acepte las capturas.

## Decisión

**`UsarInvitacion` acepta un cuerpo `multipart/form-data` opcional** con `curp`,
`placa`, `foto_documento`, `foto_rostro` y `foto_placa`, valida contra la config
del kiosko reusando `visitas.ValidarCamposCondicionales`, guarda las fotos con
`visitas.GuardarFotoVisitante` y las persiste en la misma `Visita` que ya creaba.

La opción 1 se descartó porque rompe dos garantías del flujo de invitados: crea
la visita en estado `PENDIENTE` en vez de `APROBADO` —el invitado ya venía
autorizado por el residente, mandarlo a la cola de aprobación es una
regresión— y deja el token sin consumir, o consumido por una segunda llamada que
insertaría una visita duplicada. La opción 2 arregla lo segundo pero no lo
primero, y agrega un endpoint más al ciclo de vida del token.

Para reusar la validación y el guardado de fotos desde el paquete
`invitaciones`, se exportaron tres símbolos de `visitas`:
`ValidarCamposCondicionales`, `GuardarFotoVisitante` y `ErrFormatoFotoInvalido`.
La dirección de la dependencia no cambia: `invitaciones` ya importaba `visitas`,
y hacerlo al revés crearía un ciclo.

`ValidarInvitacion` también devuelve ahora `casa_destino` resuelta, porque el
kiosko necesita mostrar a dónde va la visita mientras pide las capturas, antes
de consumir el token.

## Consecuencias

- Los tres toggles de invitado por fin significan algo, tanto en kioskos
  vehiculares como peatonales.
- Un invitado sigue entrando con una sola llamada y una sola fila en `visitas`,
  en estado `APROBADO`.
- **Compatibilidad hacia atrás:** el cuerpo se lee solo si el `Content-Type` es
  `multipart/form-data`. Un kiosko sin capturas configuradas manda el mismo POST
  vacío de siempre y el comportamiento es idéntico.
- El paquete `visitas` expone tres símbolos que antes eran internos. Es el precio
  de tener una sola definición de qué exige cada configuración; duplicar esa
  tabla de reglas en dos dominios habría sido peor.
- Si el invitado abandona el kiosko a media captura, la invitación **no** se
  consume: el token solo se marca usado cuando la visita se crea. Es el
  comportamiento deseado.
