# ADR-0027: Destino gana estructura (calle/tipo/número) sin volverse relacional

**Estado:** Aceptado
**Fecha:** 2026-08-24
**Extiende:** ADR-0007 (dominio destinos con titular)

## Contexto

`Destino.Nombre` era un campo de texto libre ("Torre B, Depto 102") sin
estructura, dado de alta uno por uno desde el dashboard. Dos problemas reales:

1. **Ni el kiosko ni la app Kigo tienen forma de elegir una casa sin leer una
   lista plana completa.** Para un fraccionamiento con decenas o cientos de
   unidades, eso no escala — ni como picker táctil en el kiosko ni como campo
   de texto libre en la app (donde además nadie valida que lo escrito
   coincida con un destino real: ver el bug de `UnirseCentro` más abajo).
2. **`casa_destino` viaja como string resuelto por casi todo el sistema.**
   `Visita.CasaDestino` y `Membresia.CasaDestino` no son FK a `Destino` — solo
   `Invitacion.DestinoID` lo es. Cualquier cambio de modelo tenía que
   respetar eso o mover medio sistema.

## Decisión

**`Destino` gana columnas estructuradas (`Calle`, `Tipo` fijo casa|edificio,
`Numero`), pero `Nombre` se sigue calculando de ahí y sigue siendo el string
que circula como `casa_destino` — no se introduce una tabla `Calle` aparte ni
se convierte `Visita`/`Membresia` a FK.**

1. `nombreDestino(calle, tipo, numero)` arma el string resuelto (ej.
   "Calle Roble · Casa 12") al crear el destino — una sola vez, no en cada
   lectura. Todo lo que ya consumía `Nombre` (kiosko, bitácora, invitaciones)
   sigue funcionando sin cambios.
2. `POST /destinos/lote`: una calle + un tipo + una lista de números crea N
   destinos en una transacción — reemplaza el alta uno-por-uno del dashboard.
   Se decidió lista libre separada por comas en vez de rango numérico:
   cubre numeración irregular (letras, saltos) con una sola UI, sin duplicar
   el formulario para los dos casos.
3. El kiosko (`CasaDestinoView`) pasa de lista plana a selección progresiva:
   calle → tipo (solo si la calle tiene los dos) → número. Mismo contrato de
   salida (`Navigator.pop(context, nombre)`) — cero cambios en quien lo
   consume.
4. **`UnirseCentro` ahora valida contra el directorio real.** No existía
   ninguna verificación: la app guardaba lo que la persona tecleaba tal cual,
   así que un "102A" del admin y un "102a" de la app nunca se conectaban, sin
   aviso para nadie. `FindCanonicoPorTenant` compara sin distinguir
   mayúsculas ni espacios y guarda el `Nombre` exacto del registro — nunca lo
   que escribió la persona. Sin coincidencia, error específico y accionable.
5. **La app Kigo no obtiene un picker** (a diferencia del kiosko) — se
   consideró exponer el directorio completo por código público a un
   dispositivo no verificado un riesgo de privacidad no aceptable (revela la
   estructura completa del fraccionamiento a cualquiera con el código). El
   texto libre + validación normalizada del punto 4 es el balance elegido.
6. Se descartó migrar automáticamente los destinos existentes (creados como
   texto libre, sin calle/tipo/número): parsear "Torre B, Depto 102" de forma
   confiable es ambiguo y se presta a errores silenciosos. Quedan como están;
   la estructura aplica solo hacia adelante.

## Consecuencias

- Alta masiva reduce dar de alta un fraccionamiento completo de N formularios
  a 1.
- El kiosko escala a cientos de destinos sin volverse una lista infinita.
- `UnirseCentro` cierra la clase de bug "typo → conexión rota sin aviso" de
  raíz, sin exponer el directorio completo a un cliente no confiable.
- El campo "casa/destino" de la app Kigo sigue siendo texto libre — el
  usuario tiene que escribirlo exactamente como el admin lo dio de alta
  (mayúsculas/espacios ya no importan, pero la calle y el número sí). Es un
  trade-off deliberado de privacidad; si el volumen de soporte lo justifica,
  el candidato a mejorar sería un endpoint público-por-código que exponga
  solo lo mínimo (ej. autocompletar de calles), no el directorio completo.
