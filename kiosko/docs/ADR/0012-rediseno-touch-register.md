# ADR-0012: Rediseño visual de TouchRegisterView

**Estado:** Aceptado
**Fecha:** 2026-07-17
**Autores:** Alberto Luna, Jesus Mendoza y Alexis Lopez

## Contexto

TouchRegisterView (ver ADR-0005) mostraba en cada paso un título y
subtítulo redundantes con la tarjeta de instrucciones (`_buildInstructionCard`,
el "recuadro gris"), y un recuadro de vista previa de cámara
(`_buildPreviewBox`, el "recuadro negro con borde naranja") que solo
mostraba un marco estático o la foto ya capturada. El botón principal era
un rectángulo ancho con ícono de flecha, y además tenía un bug de texto: en
el último paso (captura de rostro) mostraba la constante
`continueButtonText` ("Confirmar") en vez del texto propio del paso
("Capturar fotografía"), rompiendo la consistencia con el paso de INE
("Capturar INE"). Se buscaba una experiencia más limpia, con
retroalimentación visual — una guía animada — que ayude al usuario a
entender qué debe mostrar a la cámara en cada paso, sin depender de
bloques de texto ni de cajas de instrucciones estáticas.

## Decisión

- Se eliminaron el título/subtítulo de cada paso y las cajas de
  instrucciones y vista previa, reemplazándolas por un único espacio
  (`_buildVideoPlaceholder`, relación de aspecto 4:3) reservado para una
  animación guía.
- El botón principal (`_buildMainButton`) se rediseñó como círculo (antes
  rectángulo con ícono de flecha), con el texto del paso centrado y sin
  truncar (`overflow: ellipsis` removido). Se corrigió el bug de
  `continueButtonText`: el botón ahora siempre usa el texto propio del
  paso actual, igual en todos los pasos.
- La leyenda del footer ("POWERED BY KIGO · FEPRO 2026") se sacó del
  `SingleChildScrollView` y se fijó en la parte inferior de la pantalla,
  separada del borde, para que no se mueva con el scroll del contenido.
- Se construyó `IneApproachAnimation` (paso 0, captura de INE): una
  animación 100% en código Flutter (`AnimationController` con
  escala/opacidad/desplazamiento vertical en loop, sin assets externos)
  que simula una credencial acercándose a la pantalla. El diseño de la
  tarjeta se simplificó de forma iterativa a partir de una imagen de
  referencia de una INE, hasta quedar abstracto: barras de color (gris
  oscuro para posiciones de "título", gris claro para posiciones de
  "dato") en vez de texto real, sin escudo nacional ni patrón de
  holograma — deliberadamente, para que no pueda usarse como plantilla
  de una identificación falsa.
- Se construyó `FaceApproachAnimation` (paso 1, captura de rostro) con la
  misma mecánica de animación: un hombre y una mujer que se acercan,
  sostienen y se alejan desapareciendo, alternando en loop. La primera
  versión se generó como GIF pre-renderizado (`tool/generate_face_animation.dart`
  + dependencia `image`, dibujando cada frame a mano), pero se descartó
  por menor calidad visual (paleta de color cuantizada, bordes con
  aliasing) en favor de dibujar los rostros directamente con widgets de
  Flutter, igual que la tarjeta de la INE. El diseño final (busto de
  hombre y mujer con ropa, cabello, ojos ovalados negros sin cejas y
  sonrisa de "media luna" blanca) se ajustó a partir de una imagen de
  referencia de avatares proporcionada por el usuario.
- Ambas animaciones alternan automáticamente según `viewModel.currentStep`
  dentro de `_buildVideoPlaceholder`, sin lógica adicional en el ViewModel.

## Consecuencias

Positivas:
- Interfaz más limpia: menos texto y cajas redundantes, más espacio para
  la guía visual animada de cada paso.
- Ambas animaciones son código Flutter puro (sin video ni GIF de por
  medio en la versión final), lo que mantiene el tamaño del app bundle
  bajo y permite editarlas directamente en los widgets sin herramientas
  ni assets externos.
- Se corrigió el bug de texto del botón en el último paso.
- El diseño abstracto de la credencial reduce el riesgo de que la
  animación se use como plantilla de un documento de identidad falso.

Negativas / Trade-offs:
- Las animaciones dibujadas con `Positioned`/`Container` y coordenadas
  manuales son más verbosas de ajustar que un asset de diseño
  (Figma/Lottie); cualquier cambio de proporciones requiere tocar números
  dentro del widget.
- El primer enfoque de GIF (script generador + dependencia `image`) se
  construyó por completo y luego se descartó al preferir la versión
  animada en Flutter — trabajo que no se reutilizó en el resultado final.
