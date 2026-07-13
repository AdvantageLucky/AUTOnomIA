# ADR-0003: Google ML Kit Text Recognition para lectura local de INE

**Estado:** Aceptado
**Fecha:** 2026-05-25
**Autores:** Alberto Luna

## Contexto

El flujo de registro requiere leer datos de la INE del usuario: nombre
completo, CURP y clave de elector. Las opciones evaluadas fueron:
  a) Enviar la imagen a una API externa (OCR en la nube).
  b) Usar Google ML Kit Text Recognition de forma completamente local.
Los datos de una INE son información personal sensible (nombre, CURP,
clave de elector). La aplicación opera en un kiosco físico.

## Decisión

Usamos google_mlkit_text_recognition para procesar la imagen de la INE
directamente en el dispositivo. Ninguna imagen ni dato se envía a
servidores externos durante el proceso de OCR.

## Consecuencias

Positivas:
- Los datos nunca salen del dispositivo durante el escaneo.
- Funciona sin conexión a internet.
- Sin costo por llamadas a API de OCR externa.

Negativas / Trade-offs:
- El modelo de ML Kit no es perfecto: confunde O con 0 e I con 1,
  especialmente en CURP y clave de elector. Requirió implementar
  corrección posicional de caracteres (ver ADR-0004).
- La precisión varía según la calidad de la cámara y la iluminación.
- El tamaño del APK aumenta por incluir el modelo de ML localmente.