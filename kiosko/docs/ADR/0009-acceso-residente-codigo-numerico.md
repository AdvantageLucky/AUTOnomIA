# ADR-0009: Acceso de residente mediante código numérico de 5 dígitos

**Estado:** Aceptado
**Fecha:** 2026-07-10
**Autores:** Alberto Luna

## Contexto

El flujo de residente necesita una forma rápida de identificación sin
requerir documentos físicos ni biometría. Se evaluó el uso de un campo
de texto estándar, pero para un kiosco táctil el teclado nativo del
sistema operativo genera una experiencia deficiente (ocupa media pantalla,
diseño inconsistente, difícil de usar adentro del vehículo).

## Decisión

Implementamos una vista dedicada (ResidentPinView) con un teclado numérico
custom de 3×4 integrado en la UI de la aplicación. El código tiene un
límite fijo de 5 dígitos; al completarse navega automáticamente a la
pantalla de bienvenida sin requerir botón de confirmar.

La lógica del PIN (longitud máxima, getter isComplete, acumulación de
dígitos) vive en ResidentPinViewModel, y la navegación automática se
dispara en el onTapUp del último dígito dentro de la vista.

## Consecuencias

Positivas:
- Experiencia táctil consistente con el resto de la app, sin teclado
  nativo del SO.
- La navegación automática al 5to dígito elimina un paso para el usuario.
- El límite fijo de 5 dígitos simplifica la validación futura con backend.

Negativas / Trade-offs:
- Si el residente se equivoca en el último dígito ya se disparó la
  navegación — se necesitará manejo de error cuando se conecte el backend.
- El teclado custom requiere mantenimiento propio (accesibilidad, etc.).