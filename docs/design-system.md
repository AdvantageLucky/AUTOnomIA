# Sistema de diseño — AUTOnomIA

Este documento es la fuente de verdad escrita de los tokens visuales compartidos
por las 3 apps del proyecto: el dashboard admin (`backend/web/admin/`), el
kiosko (`kiosko/`) y la app de residente (`kigo-app/`).

## Principios

Las 3 apps son 3 stacks separados sin pipeline de build compartido (CSS plano +
2 apps Flutter independientes) — no hay forma de generar los 3 desde una sola
fuente sin construir tooling que hoy no se justifica. Este documento es la
alternativa: la referencia contra la que se revisa cualquier cambio de token.

**Regla de oro:** si cambias un valor de color, radio o tipografía en una app,
revisa las otras dos contra este documento antes de hacer commit.

## Paleta

| Token semántico | Valor hex | Dashboard (CSS) | Kiosko (`KigoDesign`) | kigo-app (`AppTheme`) |
|---|---|---|---|---|
| Marca | `#FF542F` | `--brand` | `brand` | `primaryOrange` |
| Marca (hover) | `#FF6B47` | *(usa `opacity: 0.88`, no un color)* | `brandHover` | `brandHover` |
| Fondo | `#09090D` (dark) / `#F2F1F7` (light) | `--bg` | `bgDark` / `bgLight` | `backgroundBlack` / `backgroundLight` |
| Superficie | `#0F1018` (dark) / `#FFFFFF` (light) | `--surface` | `surface1` / `surfaceLight` | `surfaceDark` / `surfaceLight` |
| Superficie 2 | `#141523` (dark) / `#EBEBF2` (light) | `--surface-2` | `surface2` / `surface2Light` | `surface2Dark` / `surface2Light` |
| Card (solo Flutter) | `#1A1B2E` | *(usa `--surface`)* | `surfaceCard` | `cardDark` |
| Borde | `#1E1F2E` (dark) / `#DDDCE8` (light) | `--border` | `border` / `borderLight` | `borderDark` / `borderLight` |
| Texto primario | `#ECEAF4` (dark) / `#0C0C14` (light) | `--text` | `textPrimary` / `textDark` | `textWhite` / `textDark` |
| Texto secundario | `#888AA6` (dark) / `#8A8BA8` (light) | `--text-3` | `textSecondary` / `textTertiaryLight` | `textGrey` |
| Texto terciario | `#5C5D77` (dark) / `#6B6C82` (light) | `--text-2` | `textTertiary` / `textSecondaryLight` | `textDimmed` |
| Verde (éxito) | `#2DCFA8` | `--green` | `success` | `success` |
| Rojo (error) | `#FF4D6A` | `--red` | `error` | `error` |
| Azul | `#5B8AF5` | `--blue` | `blue` | `blue` |
| Ámbar | `#FFC542` | `--amber` | `amber` | `amber` |
| Naranja (acento) | `#FF9500` | `--orange` | *(no existe como token nombrado)* | *(no existe como token nombrado)* |

## Tipografía

- **Space Grotesk** — familia base de las 3 apps. Dashboard la carga vía
  `<link>` a Google Fonts CDN (`backend/web/admin/index.html`); kiosko y
  kigo-app vía el paquete `google_fonts` (`GoogleFonts.spaceGroteskTextTheme`).
- **JetBrains Mono** — para datos "literales" que no son prosa: CURP, PIN,
  placa. Vigente en las 3 apps:
  - Dashboard: vía `<link>` a Google Fonts CDN, clase `'JetBrains Mono'` directa en CSS.
  - Kiosko: `KigoDesign.mono(TextStyle base)` — usado en la placa de `ConfirmarPlacaView`.
  - kigo-app: `AppTheme.mono(TextStyle base)` — usado en el PIN de `MyQrView`.

## Radios

| Token | Valor | Uso recomendado | Dashboard | Kiosko/kigo-app |
|---|---|---|---|---|
| `sm` | 6px | Controles pequeños, badges, botones | `--radius-sm` | `radiusSm` |
| base | 10px | Inputs, paneles, contenedores generales | `--radius` | `radius` |
| `lg` | 16px | Cards (superficies "-card" específicamente) | `--radius-lg` | `radiusLg` |
| `xl` | 22px | Superficies grandes / modales | *(sin token CSS — no usado hoy en el dashboard)* | `radiusXl` |

## Inconsistencias resueltas en este ciclo (2026-08-29)

1. **Radio de botón en kigo-app** — usaba `radius` (10px), dashboard y kiosko
   ya usaban `radiusSm` (6px). Alineado a `radiusSm` en las 3.
2. **Radio de card** — dashboard usaba `--radius` (10px) en sus 4 selectores
   de card (`.public-code-card`, `.stat-card`, `.quick-card`, `.acceso-card`),
   kigo-app ya usaba `radiusLg` (16px), kiosko no fijaba `shape` (default
   implícito de Material3). Estandarizado a `lg`/16px en las 3.
3. **JetBrains Mono** — solo existía en el dashboard. Extendido a kiosko
   (placa) y kigo-app (PIN) vía un helper `mono(TextStyle base)` con el mismo
   nombre en ambas apps Flutter.
