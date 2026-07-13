# ADR-0006: Google ML Kit Face Detection para validación local de rostro

**Estado:** Aceptado
**Fecha:** 2026-06-10
**Autores:** Alberto Luna

## Contexto

El paso 2 del registro requiere capturar una foto del rostro del visitante.
Era necesario validar que la foto contiene efectivamente un rostro y que
no está demasiado lejos de la cámara (foto válida para identificación).
Se evaluaron las mismas opciones que para el OCR: API externa vs. local.

## Decisión

Usamos google_mlkit_face_detection procesando la imagen localmente en el
dispositivo. Consideramos que hay un rostro válido cuando el área del
bounding box del rostro detectado supera 8,000 px² (face.boundingBox.width
× face.boundingBox.height > 8000), lo que filtra detecciones de rostros
demasiado pequeños o lejanos.

La cámara frontal se usa por defecto para facilitar la captura por parte
del visitante.

## Consecuencias

Positivas:
- Consistente con ADR-0003: ninguna biometría sale del dispositivo.
- Funciona sin conexión.
- La validación por área es simple y efectiva para el caso de uso
  de un kiosco donde el usuario está frente a la pantalla.

Negativas / Trade-offs:
- El umbral de 8,000 px² es empírico y puede requerir ajuste según
  la cámara del dispositivo donde se instale el kiosco.
- No valida vivacidad (liveness): una foto de una foto pasaría la
  validación de área.
- Aumenta el tamaño del APK al incluir un segundo modelo de ML Kit.