# ADR-0004: Corrección posicional de caracteres OCR para CURP y clave de elector

**Estado:** Aceptado
**Fecha:** 2026-05-28
**Autores:** Alberto Luna 

## Contexto

ML Kit confunde sistemáticamente O/0 e I/1 al leer la INE. La CURP y la
clave de elector tienen un formato estrictamente definido: ciertas
posiciones son siempre letras y otras son siempre dígitos. Una regex
directa sobre el texto crudo fallaba en INEs distintas a la del
desarrollador porque los errores de OCR cambiaban la longitud o el
patrón del resultado.

## Decisión

Implementamos corrección posicional en detector_servicio.dart:
  - Posiciones 0-3 de la CURP (letras): 0 → O, 1 → I.
  - Posiciones 4-9 de la CURP (dígitos de fecha): O → 0, I → 1.
  - Posición 10 de la CURP (H o M): se valida explícitamente.
  - La clave de elector se reconstruye con la misma lógica por segmento.
La corrección se aplica antes de validar el patrón con regex.

## Consecuencias

Positivas:
- Aumenta significativamente la tasa de lectura exitosa en INEs de
  diferentes generaciones y estados de conservación.
- No depende de que ML Kit sea perfecto.

Negativas / Trade-offs:
- La lógica de corrección está acoplada al formato específico de la INE
  mexicana. Cualquier cambio en el formato de la CURP requiere actualizar
  las posiciones.
- Añade complejidad al servicio de detección.