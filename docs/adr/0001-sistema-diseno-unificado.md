# 0001 - Sistema de diseño unificado entre los tres productos

## Status
Accepted

## Context
AUTOnomIA son tres interfaces construidas por separado y en momentos distintos: el dashboard web
(HTML/CSS/JS vanilla), la app del kiosko (Flutter) y la app del residente (Flutter). Cada una había
crecido con su propio criterio visual:

- **Tipografía distinta en cada producto**: Arial en el kiosko, Poppins en la app residente,
  Space Grotesk en el dashboard.
- **Paletas divergentes para el mismo concepto**: el naranja de marca era `#FF6B00` en la app
  residente y `#FF542F` en el dashboard. El fondo oscuro era `#121212`, `#171313` o `#09090D` según
  el archivo.
- **Valores literales repartidos por las vistas**: alrededor de 80 literales hexadecimales en unos
  20 archivos solo en la app del kiosko, sin ninguna constante intermedia.

El efecto para el usuario es que el kiosko y la app del residente no parecen el mismo producto. En
una feria de proyectos como FEPRO, donde la evaluación es en buena medida perceptual y comparativa,
la incoherencia visual descuenta directamente.

## Decision
El **dashboard web es la referencia**, por ser la interfaz más madura. Sus *custom properties* CSS
son la fuente de verdad de los tokens de diseño.

- Cada app Flutter declara los mismos tokens como `static const`, mapeados 1:1 contra las variables
  CSS del dashboard: `KigoDesign` en el kiosko y `AppTheme` en la app del residente.
- **Tipografía única**: Space Grotesk en los tres productos — vía `google_fonts` en Flutter, vía
  Google Fonts CDN en el dashboard.
- Las vistas consumen los tokens **siempre por nombre**. No se escriben literales hexadecimales en
  el código de UI.
- Los temas claro y oscuro se derivan de los mismos tokens; ningún componente define un color que
  exista solo en uno de los dos temas.

## Consequences
- Cambiar el color de marca pasa a ser editar tres constantes en lugar de buscar decenas de
  literales repartidos por el árbol de archivos.
- Los tokens están **duplicados en tres lenguajes** (CSS y Dart ×2) y la sincronización es manual:
  nada impide que se desalineen. Es el costo aceptado frente a montar un *pipeline* de generación de
  design tokens, desproporcionado para el tamaño del proyecto.
- `google_fonts` descarga la tipografía en tiempo de ejecución la primera vez. En los tests hay que
  desactivar el *fetch* con `GoogleFonts.config.allowRuntimeFetching = false`; aun así, construir un
  `ThemeData` dispara la carga, por lo que los tests verifican las constantes de color directamente
  en vez de instanciar el tema.
- Los paneles que dependen de un fondo oscuro para verse —superficies translúcidas de tipo *glass*—
  no pueden heredar el tema de la página. Se resuelve redefiniendo los tokens dentro del ámbito de
  ese componente para fijarlo en oscuro, en lugar de parchear regla por regla.
