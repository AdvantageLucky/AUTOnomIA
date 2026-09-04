# Kiosko de Salida — AUTOnomIA

Segundo dispositivo, aparte del kiosko principal: registra la salida de un visitante con una sola foto de rostro, sin OCR ni QR. Dos pantallas:

1. **Salir** — un botón.
2. **Captura de rostro** — mismo detector/guía visual que el kiosko principal (`ScannerRostroWidget`), auto-captura al detectar un rostro válido y centrado.

Al capturar, sube la foto a `POST /api/v1/kioskos/:id/salidas` y vuelve a la pantalla de reposo. El backend la guarda como una fila en la tabla `salidas` (bitácora mínima, sin resolución de identidad — no hay INE ni QR de por medio, nada contra qué correlacionar).

## Activación

Mismo protocolo RFC 8628 que el kiosko principal: al primer arranque pide un código de 8 caracteres que el admin aprueba desde `Kioskos → Nuevo kiosko` en el dashboard. Es un kiosko más en la tabla `kioskos` — no hay tabla ni tipo aparte para "kiosko de salida".

## Comandos

```bash
flutter pub get
flutter run
flutter build apk --release
```

## Qué se reusó del kiosko principal, y qué no

Reusa (copiado, no importado como paquete — son proyectos Flutter separados): `KigoDesign` (tema), `MarcoGuiaCamara` + `CheckpointSweep` (guía visual de cámara), `VistaPreviaCamara`/`CamaraKiosko` (mismo mecanismo de rotación por `--dart-define`), `FaceDetectorServicio` (detección on-device con ML Kit), el diálogo de consentimiento, y el flujo de activación RFC 8628.

No incluye: OCR de INE, escaneo de QR/PIN, modo offline, LED del hardware F10, ni el sistema de configuración remota (SSE) — este dispositivo no tiene nada que configurar.
