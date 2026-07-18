# 0010 - i18n y theming en el dashboard con JS y CSS vanilla

## Status
Accepted

## Context
El dashboard necesita soporte para dos idiomas (español / inglés) y dos temas visuales
(claro / oscuro). Las opciones habituales en ecosistemas JS son librerías como i18next para i18n y
soluciones CSS-in-JS o frameworks de componentes para theming. Pero el dashboard es JS vanilla
sin bundler (ver [0009](0009-google-oauth-en-dashboard-sin-bundler.md)) — introducir un gestor
de paquetes npm solo para resolver i18n o theming sería desproporcionado.

## Decision

**i18n**: un objeto global `STRINGS = { es: {...}, en: {...} }` con todas las cadenas. La función
`t(key)` devuelve `STRINGS[currentLang][key]`. Los elementos del DOM que necesitan traducción
llevan el atributo `data-i18n="key"`; `applyI18n()` los recorre y les asigna `textContent`.
Las cadenas dinámicas (plurales, interpolación) son funciones en el objeto:
`visits: n => \`${n} visita${n !== 1 ? 's' : ''}\``. El idioma activo se guarda en
`localStorage` con la clave `autonomia_lang` y se inicializa leyendo ese valor o detectando
`navigator.language`.

**Theming**: CSS custom properties (`--bg`, `--text`, `--accent`, etc.) definidas en `:root`
para el tema claro. El tema oscuro las redefine bajo `[data-theme="dark"]` en el elemento raíz.
`initTheme()` lee `localStorage` (`autonomia_theme`) o `prefers-color-scheme`; `setTheme()`
escribe `document.documentElement.dataset.theme`. El toggle en el sidebar escribe en localStorage
y llama a `setTheme()`. No hay clases de utilidad ni variables duplicadas — el sistema de tokens
garantiza que cada componente que usa `var(--bg)` responde al toggle automáticamente.

## Consequences
- Agregar un nuevo idioma requiere añadir un bloque `{ idioma: {...} }` en `STRINGS` y el botón
  del toggle — no hay archivo de traducción externo ni proceso de build.
- Las cadenas que usan funciones para plurales o interpolación no pueden tener `data-i18n` en el
  HTML estático; se aplican directamente en el handler JS que rellena el elemento. Eso es un
  inconveniente menor versus la simplicidad total de la solución.
- El theming depende de CSS custom properties — soportado en todos los navegadores modernos.
  IE11 no es un target para este sistema.
- El atributo `[hidden]` del HTML debe convivir correctamente con `display: flex` de los overlays;
  se requiere la regla `[hidden] { display: none !important }` para que el CSS del autor no
  anule el comportamiento nativo del atributo `hidden` en los modales.
