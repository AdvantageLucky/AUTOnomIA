# ADR-0016: Huella facial (embedding) calculada on-device con MobileFaceNet

**Estado:** Aceptado
**Fecha:** 2026-08-10
**Autores:** (completar)

## Contexto

La vista de acceso por rostro del residente (`ResidenteAccesoView`) solo mostraba
un círculo estático con el texto "Reconocimiento facial en configuración /
Próximamente disponible". El objetivo era que el acceso por rostro funcionara de
verdad: activar la cámara, mostrar el video en vivo y comparar ese rostro contra
los residentes registrados del edificio.

`google_mlkit_face_detection` (ya usado en ADR-0006 para el registro de
visitantes) solo detecta que hay un rostro y sus landmarks — **no** identifica de
quién es. Ni el kiosko ni el backend tenían capacidad alguna de reconocimiento
facial: la columna `residentes.embedding` existía en la base de datos pero
ningún código la calculaba (comentario en el modelo Go: "nil hasta tener
modelo").

## Decisión

1. **Cámara en vivo dentro del círculo existente.** Se activa la cámara frontal
   (paquete `camera`, ya usado en `scanner_rostro_widget.dart`) tras el
   consentimiento ya existente en la vista, y su preview se recorta en forma
   circular con `FittedBox(fit: BoxFit.cover)`.

2. **El embedding se calcula 100% en el dispositivo.** Se integró MobileFaceNet
   vía `tflite_flutter` (modelo `.tflite` de ~5MB, 192 dimensiones, empaquetado
   como asset). El nuevo `ReconocimientoFacialServicio` reutiliza
   `FaceDetectorServicio` (ADR-0006) para confirmar que hay un rostro antes de
   correr la inferencia más pesada, recorta la región del rostro con margen del
   15%, la redimensiona a 112×112 y corre el modelo. La foto capturada nunca se
   sube a ningún servidor — solo el vector resultante.

3. **Loop de verificación periódico.** Mientras la cámara está activa, un
   `Timer.periodic` cada 1.5s toma una foto silenciosa
   (`_cameraController.takePicture()`), valida presencia de rostro, calcula el
   embedding y lo envía al nuevo endpoint del backend
   (`KioskoServicio.verificarRostroResidente`). Se exigen **2 coincidencias
   consecutivas contra el mismo residente** (mismo nombre + casa_destino en dos
   respuestas seguidas) antes de dar el acceso por bueno — mitigación básica de
   falsos positivos, no es liveness/anti-spoofing real.

4. **Convergencia con el flujo de PIN.** En éxito, se navega exactamente a la
   misma `ResidentWelcomeView` / `ResidentWelcomeViewModel` que ya usa el login
   por PIN (`resident_pin_view.dart`), así ambos caminos de entrada se sienten
   idénticos del lado del usuario.

5. **Aviso de privacidad actualizado.** El texto de consentimiento se corrigió
   para reflejar que lo que viaja al backend es la huella matemática (embedding),
   nunca la imagen — ya no dice "comparado localmente" porque la comparación en
   sí ocurre en el backend (ver ADR del backend "Comparación de rostro contra
   residentes registrados").

## Consecuencias

Positivas:
- Ninguna imagen biométrica sale nunca del kiosko — coherente con ADR-0006 y
  ADR-0007 (consentimiento de cámara).
- Reutiliza patrones ya existentes (captura por archivo, `FaceDetectorServicio`,
  el mismo diálogo de consentimiento) en vez de introducir un stream de cámara
  paralelo.
- El acceso por rostro y por PIN terminan en la misma experiencia post-login.

Negativas / Trade-offs:
- **El modelo MobileFaceNet integrado (tomado de un repo comunitario) no tiene
  licencia de redistribución clara para sus pesos preentrenados** — se decidió
  avanzar así para el prototipo, pero debe revisarse antes de cualquier
  lanzamiento comercial.
- Sin liveness real: una foto impresa o una pantalla podría, en teoría, superar
  la validación de ML Kit y el umbral de similitud.
- Cada intento de verificación depende de red (la comparación corre en el
  backend) — consistente con el resto del flujo del kiosko, que ya depende de
  red para todo, pero sí es una dependencia nueva específicamente para el
  reconocimiento facial.
- Agrega ~5MB de asset más la librería nativa de `tflite_flutter` al tamaño del
  APK.
- No se construyó ninguna forma de que un residente *existente* capture su
  rostro de referencia dentro de esta app — eso vive fuera de este ADR (dashboard
  admin o la app `residente/`, ninguna de las dos se tocó).
