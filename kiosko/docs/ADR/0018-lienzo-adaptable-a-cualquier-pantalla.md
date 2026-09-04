# ADR-0018: Un lienzo escalado para servir el mismo diseño en cualquier pantalla

**Estado:** Aceptado
**Fecha:** 2026-09-03
**Relacionado:** ADR-0012 (rediseño de TouchRegister), `core/widgets/PantallaAdaptable`

## Contexto

Todo el kiosko está dibujado contra un panel de 800x1280 (el F10 en vertical) y
la geometría está clavada en píxeles lógicos a propósito: `430 son 430 mientras
quepan` en el recuadro del escáner QR, 150 de alto el CTA del registro, 76 el
botón del asistente. No son números arbitrarios, son medidas de señalética —
pensadas para leerse de pie y a un brazo de distancia — y ya se ajustaron a mano
contra el panel real varias veces.

El equipo se empezó a instalar en tablets de otras medidas, y las pruebas se
hacen en teléfonos. Ahí el diseño se rompía por los dos lados: en una pantalla
más angosta que 800 las filas de cabecera desbordaban (el bloque de marca, el
título "MODO OPERADOR", la etiqueta del CTA), y en una pantalla más grande todo
quedaba chico y perdido en el centro del vidrio, porque nada crece con el
lienzo.

Las opciones eran:

1. **Reescribir cada medida como fracción del lienzo.** Toca las ~50 pantallas y
   widgets, cambia el diseño en el panel real (una fracción que da 430 en 800 da
   otra cosa en cualquier otro ancho) y hay que volver a ajustar todo a mano.
2. **Escalar el diseño completo a la pantalla, con franjas negras**
   (`FittedBox` sobre un lienzo fijo de 800x1280). Conserva el diseño exacto,
   pero desperdicia vidrio: en un teléfono deja ~230px de barras arriba y abajo.
3. **Escalar el diseño completo y regalarle el sobrante al layout.** Igual que la
   2, pero el eje que sobra no se rellena con barras: se le entrega a la vista
   como espacio lógico extra.

## Decisión

**Opción 3**, en `core/widgets/LienzoAdaptable`, montado una sola vez en el
`builder` del `MaterialApp` — por donde pasan todas las rutas, diálogos y
overlays.

1. **Factor uniforme.** Se dibuja todo a `min(ancho/800, alto/1280)`, así que en
   cualquier pantalla el diseño se ve con las mismas proporciones que en el
   panel. En 800x1280 el factor es exactamente 1: no cambia un pixel de lo que
   ya estaba ajustado ahí.

2. **El eje que sobra es espacio lógico, no franjas.** Un teléfono de 411x891
   escala a 0.51 y la vista recibe un lienzo de 800x1733: el ancho es el de
   siempre y el alto de más lo reparten los `Spacer` y `PantallaAdaptable` que
   las pantallas ya tenían. Ninguna vista recibe nunca menos de 800x1280.

3. **Tope de ancho en 1.5x.** Pasado eso el contenido se centra y los márgenes
   se pintan del color del tema. El kiosko es un diseño vertical: en una tablet
   apaisada, una fila de extremo a extremo (2048 lógicos) se recorre con la
   vista en vez de leerse.

4. **Los recortes del sistema se convierten a la escala.** `padding`,
   `viewPadding`, `viewInsets` y `systemGestureInsets` se dividen entre el
   factor antes de pasarlos hacia abajo; si no, el `SafeArea` de cada pantalla
   reservaría de más.

Aparte del lienzo, las pantallas se arreglaron para que tampoco desborden por su
cuenta: lo elástico de cada fila (el bloque de marca, la etiqueta de un CTA, el
teléfono de contacto) va en `Flexible`, y los botones de alto fijo pasaron a
alto mínimo para poder crecer cuando su etiqueta salta de renglón.

## Consecuencias

- El mismo APK sirve el mismo diseño en el panel, en una tablet de 7" o de 10" y
  en un teléfono, sin flavors ni layouts alternos.
- El diseño de referencia sigue siendo 800x1280 y se sigue ajustando ahí: quien
  toque una pantalla no tiene que pensar en otras medidas, sólo en no clavar
  anchos que no puedan encoger.
- `MediaQuery.sizeOf` devuelve el lienzo lógico, no la pantalla física. Es lo
  que quiere el código que calcula geometría (`rectRecuadroQr`), pero cualquier
  cosa que necesite píxeles reales del equipo tiene que pedirlos a la vista.
- `test/pantallas_adaptables_test.dart` monta cada pantalla y cada hoja en seis
  lienzos (panel, tablets en ambas orientaciones, teléfonos) y falla si algo
  desborda: es la red que sostiene lo anterior.
- El texto y la cámara se dibujan escalados. Al ser una transformación de
  pintado (no un bitmap estirado) no se pierde nitidez, pero un `1.0` de borde
  en el diseño puede quedar en `0.5` reales en una pantalla chica.
