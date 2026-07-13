# ADR-0002: Arquitectura por feature en lugar de arquitectura por tipo de archivo

**Estado:** Aceptado
**Fecha:** 2026-05-20
**Autores:** Jesus Mendoza y Alberto Luna

## Contexto

El proyecto comenzó con una organización por tipo de archivo: lib/views/,
lib/models/, lib/services/, lib/viewmodels/. Al crecer el número de
funcionalidades (registro, welcome, servicios OCR, servicios de rostro),
los archivos relacionados quedaban dispersos. Modificar el flujo de registro
requería navegar entre cuatro carpetas distintas.

## Decisión

Migramos a arquitectura por feature bajo lib/features/. Cada feature
contiene sus propias subcarpetas de models/, services/, viewmodels/ y
views/. Los servicios verdaderamente transversales permanecen en lib/core/.

## Consecuencias

Positivas:
- Todo el código de una funcionalidad vive en un solo lugar.
- Menor acoplamiento accidental entre features.
- Escala mejor al añadir nuevas features al kiosco.

Negativas / Trade-offs:
- La migración requirió actualizar todos los imports del proyecto.
- Features pequeñas como welcome tienen más carpetas de las que necesitan.
- Requiere criterio claro para decidir si algo va en features/ o en core/.