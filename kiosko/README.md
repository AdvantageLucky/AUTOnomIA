# kigo_kiosco

App Flutter que corre en el dispositivo físico del kiosko de AUTOnomIA. Es la interfaz con la que
interactúa el visitante en la entrada: lee su INE, valida su rostro y registra el acceso contra el
backend.

Está pensada como **dispositivo dedicado y desatendido**: arranca en modo inmersivo
(`SystemUiMode.immersiveSticky`), sin barra de estado ni de navegación, y no ofrece forma de salir
de la app.

## Comandos

```bash
flutter pub get          # instalar dependencias
flutter run              # correr en dispositivo/emulador conectado
flutter analyze          # análisis estático
flutter test             # tests
flutter build apk        # APK de release (Android es el destino principal)
```

## Activación del dispositivo

El kiosko no se configura escribiendo credenciales a mano. Al primer arranque, si no hay sesión
guardada, muestra la pantalla de activación:

1. Pide un código al backend (`POST /auth/device/authorize`) y muestra en pantalla un `user_code`
   de 8 caracteres y un QR.
2. El administrador escribe ese código en el dashboard web y da de alta el kiosko.
3. La app, que está haciendo *polling*, recibe su token de sesión y arranca el flujo normal.

Es el *Device Authorization Grant* de RFC 8628 — ver
[ADR 0019](../backend/docs/adr/0019-activacion-kiosko-device-authorization-grant.md).

Si el administrador elimina el kiosko desde el dashboard, el backend revoca las sesiones, la app
detecta el `401` y vuelve por sí sola a la pantalla de activación.

## Arquitectura

**MVVM con Provider** (`ChangeNotifier`). La navegación es imperativa: cada pantalla empuja la
siguiente con `Navigator.push`, no hay router declarativo.

```
lib/
├── core/                    código transversal a features
│   ├── models/              KioskoConfig
│   ├── notifiers/           KioskoConfigNotifier (config remota + estado de activación)
│   ├── services/            TextToSpeakServicio (TTS del agente "Kigo")
│   └── theme/               KigoDesign — tokens de color, radio y tipografía
├── features/
│   ├── activacion/          flujo RFC 8628: modelo, viewmodel y pantalla del código
│   ├── welcome/             pantalla de bienvenida y selección de tipo de visitante
│   ├── registro/            flujo de registro táctil del visitante
│   └── residente/           acceso de residentes por PIN
```

Los imports internos usan rutas de paquete (`package:kigo_kiosco/...`), no rutas relativas.

### Flujo de registro táctil

`WelcomeView` → `TouchRegisterView` (3 pasos) → `ConfirmDataView`:

1. **Paso 1 — INE**: captura con cámara; `DetectorServicio.analizarIne()` extrae CURP, clave de
   elector y nombre por OCR *on-device* (`google_mlkit_text_recognition`).
2. **Paso 2 — Rostro**: `FaceDetectorServicio.tieneRostroValido()` confirma que hay una cara en la
   foto (`google_mlkit_face_detection`).
3. **Confirmación**: se envía `multipart/form-data` a `POST /accesos/:id/visitantes`.

### Decisiones de diseño

- **Todo el ML corre on-device.** No hay llamadas a APIs externas de IA; `google_mlkit_*` usa los
  modelos que Google descarga al dispositivo.
- **El OCR corrige confusiones típicas** (`O↔0`, `I↔1`) apoyándose en la estructura fija de la CURP
  y de la clave de elector, ambas de 18 caracteres.
- **La autenticación usa el token de sesión opaco del kiosko**, no JWT. El JWT es exclusivo del
  dashboard de administración.
- **La configuración llega del backend por SSE**: tema, idioma, qué fotos son obligatorias y
  horarios se aplican en caliente sin reiniciar la app.

## Sistema de diseño

Los colores, radios y tipografía viven en `KigoDesign` (`lib/core/theme/kigo_design.dart`) y están
alineados 1:1 con los del dashboard web y la app del residente. **No se escriben literales
hexadecimales en las vistas** — ver
[ADR 0001 de producto](../docs/adr/0001-sistema-diseno-unificado.md).
