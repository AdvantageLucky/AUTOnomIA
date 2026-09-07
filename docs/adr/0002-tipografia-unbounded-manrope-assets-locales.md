# 0002 - Rebranding tipográfico a Unbounded/Manrope/JetBrains Mono, empaquetados localmente

## Status
Accepted

(Supersede parcialmente a [0001](0001-sistema-diseno-unificado.md): solo la tipografía y su
mecanismo de entrega — la paleta de colores y el resto de los tokens de [0001](0001-sistema-diseno-unificado.md) siguen vigentes sin cambio)

## Context
[0001](0001-sistema-diseno-unificado.md) unificó los tres productos en Space Grotesk, cargada vía
Google Fonts: `google_fonts` en Flutter, CDN de Google Fonts en el dashboard. Esa decisión traía dos
problemas que solo se hicieron evidentes en el uso real:

- **Dependencia de red en tiempo de ejecución.** `google_fonts` descarga el archivo la primera vez
  que se usa; en el kiosko y en kigo-app eso significa que la primera pantalla de cada instalación
  nueva puede mostrarse con la tipografía de sistema mientras la descarga termina, y los tests deben
  desactivar el *fetch* (`GoogleFonts.config.allowRuntimeFetching = false`) para no depender de red.
- **Identidad visual genérica.** Al mismo tiempo que este cambio, el proyecto pasó de llamarse
  "Kigo" a "AUTOnomIA" de cara al usuario (ícono de marca nuevo, texto "powered by" retirado del
  kiosko). Space Grotesk es una tipografía de uso extendido en productos de terceros y no distinguía
  la marca en una feria de proyectos.

## Decision
Los tres productos migran el mismo día (2026-09-02) a la misma pareja tipográfica, empaquetada como
archivo local en cada uno — nunca vía red en tiempo de ejecución.

- **Unbounded** para titulares (trazo grueso, tipo señalética) y **Manrope** para el resto del
  cuerpo de texto, en el dashboard (`backend/web/admin/`), el kiosko y kigo-app.
- **JetBrains Mono** para datos "literales" que deben leerse carácter por carácter sin ambigüedad:
  PIN, placa, CURP — mismo tratamiento en las tres interfaces, para que un residente vea su PIN en
  kigo-app con el mismo lenguaje visual que un admin ve una placa en el dashboard.
- **Empaquetado como asset local en los tres**, no vía `google_fonts` ni CDN: `assets/fonts/*.ttf`
  (variable fonts) en ambas apps Flutter, y `@font-face` con archivos servidos por el propio backend
  en el dashboard (`backend/web/admin/fonts/`). Ninguno de los tres productos vuelve a depender de la
  red del dispositivo/navegador para mostrar su tipografía.
- La paleta de colores, radios y demás tokens de [0001](0001-sistema-diseno-unificado.md) no
  cambian — solo la tipografía y cómo se sirve.

## Consequences
- Ninguna instalación nueva muestra una tipografía "de sistema" mientras algo descarga: el archivo
  ya está en el binario/paquete servido.
- El tamaño de cada APK y del bundle del dashboard crece por los archivos de fuente empaquetados
  (variable fonts, más pesadas que un peso estático único mínimo pero cubren toda la familia de
  pesos sin múltiples archivos).
- Los tres productos vuelven a estar sincronizados en tipografía, pero el mecanismo de sincronía
  sigue siendo manual (mismo problema que ya aceptaba [0001](0001-sistema-diseno-unificado.md) para
  el resto de los tokens): nada impide que un producto actualice su archivo `.ttf` sin que los otros
  dos lo hagan.
- Cambiar de tipografía otra vez implica redistribuir un archivo nuevo en tres lugares (dos APKs +
  el servidor del dashboard), no solo cambiar una referencia a un nombre de familia en Google Fonts.
