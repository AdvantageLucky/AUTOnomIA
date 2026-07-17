# 0007 - Dominio destinos con titular para verificación STT del kiosko

## Status
Accepted

## Context
El kiosko necesita que el visitante indique a qué unidad (casa, departamento) va. La forma
original era un campo de texto libre (`casa_destino: string`) que el visitante escribe sin
restricciones. Esto tiene dos problemas:

1. **Validación imposible**: con texto libre no hay forma de saber si "Torre B depto 102" y
   "Dpto 102 Torre-B" son el mismo destino.
2. **Verificación de identidad del titular bloqueada**: el flujo futuro de verificación por voz
   (STT + IA) necesita que el sistema sepa quién es el titular de la unidad a la que se
   quiere acceder, para poder contrastar esa información con lo que dice el visitante.

## Decision
Crear el dominio `destinos/` con el modelo `Destino { Nombre, Titular, AccesoID }`. Cada
`Acceso` (entrada de condominio) tiene su propio catálogo de destinos, administrado por el Admin
desde el dashboard. El kiosko consulta `GET /accesos/:id/destinos/` (protegido con
`RequireAcceso`) y presenta la lista al visitante para que seleccione de un dropdown, no un campo
de texto libre.

El campo `Titular` es obligatorio y expone a quién notificar/verificar cuando llega un visitante
a esa unidad — es el dato que el módulo de STT usará para preguntar "¿el titular X te está
esperando?".

La creación de destinos (`POST /accesos/:id/destinos/`) está protegida con `RequireAdmin` para
que solo el administrador pueda mantener el catálogo.

## Consequences
- El campo `casa_destino` en `Visita` sigue siendo texto libre (lo que el visitante seleccionó),
  pero su fuente es el catálogo de `Destino.Nombre`, no entrada arbitraria.
- El módulo de STT/IA del kiosko puede hacer `GET /accesos/:id/destinos/` al inicio del flujo de
  registro para tener la lista completa con sus titulares, sin necesidad de un endpoint adicional.
- Si el Admin no ha cargado destinos, la lista estará vacía y el kiosko mostrará un mensaje
  de configuración pendiente.
- Mantener el catálogo actualizado (mudanzas, nuevos residentes) es responsabilidad del Admin.
