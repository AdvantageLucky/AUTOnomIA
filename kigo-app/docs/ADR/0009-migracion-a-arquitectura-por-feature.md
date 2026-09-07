# ADR-0009: Migración a arquitectura por feature, alineada con kiosko y kiosko-salida

**Estado:** Aceptado
**Fecha:** 2026-09-06
**Reemplaza a:** [ADR-0002](0002-organizacion-por-tipo-de-archivo.md)
**Relacionado:** kiosko ADR-0002 (arquitectura por feature)

## Contexto

ADR-0002 aceptó organizar kigo-app por tipo de archivo (`lib/models/`, `lib/services/`,
`lib/viewmodels/`, `lib/views/`, `lib/widgets/`) razonando que la app tenía una superficie chica
frente al kiosko. En la práctica, kigo-app llegó a 68 archivos Dart en `lib/` — comparable al kiosko
cuando este migró a `features/` (ADR-0002 de kiosko) — y las cuatro apps Flutter del monorepo que sí
siguen el convenio de organización por funcionalidad (`backend` por dominio en
`internal/domain/<dominio>/`, `kiosko` y `kiosko-salida` por `features/<nombre>/`) dejaron a kigo-app
como la única excepción real. Revisando el árbol de `lib/` junto a sus archivos hermanos, la
organización por tipo ya mezclaba modelos, viewmodels y vistas de seis dominios de negocio distintos
(onboarding, invitar, solicitudes, compañeros de casa, ajustes, shell) en las mismas cuatro carpetas
planas, sin ningún indicio en la ruta del archivo de a qué flujo pertenecía.

## Decisión

kigo-app adopta la misma convención que kiosko y kiosko-salida: `lib/core/` para lo verdaderamente
transversal, `lib/features/<nombre>/{models,services,viewmodels,views,widgets}` para cada dominio de
negocio.

1. **`core/`** — `AuthViewModel` y `SettingsViewModel` (registrados globalmente en `main.dart`,
   consumidos por prácticamente toda la app), `ApiService`, `PushService`, `DeepLinkServicio`,
   `AppTheme`, `AppLocalizations`, `membresia_model` (la `Membresia` es un concepto de sesión, no de
   un feature concreto) y los widgets de UI genéricos (`kigo_list_row`, `kigo_primary_button`,
   `kigo_text_field`).

2. **`features/onboarding/`** — todo lo que ya vivía bajo `views/onboarding/` (el wizard completo:
   bienvenida, teléfono, OTP, identidad INE+rostro con su respaldo Kigo Verify, unirse a centro),
   más `ine_ocr_model` y los servicios que solo ese wizard usa (`detector_ine_servicio`,
   `face_detector_servicio`, `reconocimiento_facial_servicio`, `camera_permission_servicio`,
   `kigo_verify_servicio`). `join_centro_view` también vive aquí aunque `settings/` lo reutilice para
   unirse a un segundo centro — es un import cruzado entre features, igual que kiosko reutiliza
   servicios de `registro/` desde `registro_vehicular/`.

3. **`features/invitar/`**, **`features/solicitudes/`**, **`features/companeros_casa/`**,
   **`features/settings/`** agrupan cada uno su propio modelo/viewmodel/vista. `solicitudes/` incluye
   además `identidades_confianza_viewmodel` y `identidad_resumen_model`, porque
   `SolicitudesView` los compone junto con pendientes e historial en una sola pantalla de 3 pestañas
   internas — separarlos en un feature aparte habría partido en dos algo que se usa y se navega como
   una sola unidad.

4. **`features/shell/`** agrupa `KigoShell`, `SplashView` y `DashboardView` — código de arranque y
   navegación raíz que no pertenece a ningún dominio de negocio pero tampoco es un servicio
   transversal reutilizable, así que no calza en `core/` bajo el criterio de kiosko.

5. **Todos los imports internos pasan a `package:kigo_user/...` absoluto**, reemplazando tanto los
   imports relativos (`../../../../services/...`) como los `package:` que ya existían. Es el mismo
   estilo que usa kiosko casi sin excepción (52 de 53 imports internos) — mover un archivo ya no
   obliga a recalcular la profundidad relativa de cada import que lo referencia.

## Consecuencias

- El árbol de `kigo-app/lib/` ahora se lee igual que el de `kiosko/lib/` y `kiosko-salida/lib/`:
  alguien que conoce un subproyecto reconoce la estructura de los otros dos sin aprender un segundo
  criterio de organización.
- `DashboardView` quedó movida a `features/shell/views/` tal cual estaba — durante la migración se
  detectó que no la importa ningún otro archivo (la ruta `/dashboard` en `main.dart` en realidad
  monta `KigoShell`). Es código muerto preexistente a este ADR; no se borró aquí porque no es parte
  de una migración de carpetas, pero queda documentado para que se retire aparte.
- La migración tocó los 67 archivos no-`main.dart` de `lib/` y los 6 archivos de `test/` (solo sus
  imports) en un único cambio mecánico. `dart analyze` no reportó ningún error de imports rotos tras
  la migración — los 40 issues preexistentes (`withOpacity` deprecado, `use_build_context_synchronously`,
  etc.) no están relacionados con este ADR.
- El `README.md` de la app se actualizó para reflejar el árbol nuevo; la sección "Alta y acceso" del
  mismo README sigue describiendo el modelo `Residente` anterior a ADR-0003 y continúa pendiente de
  corregirse, sin relación con este ADR.
- Como ya anticipaba ADR-0002, el wizard de onboarding fue la única carpeta que ya rompía el patrón
  por tipo de archivo antes de esta migración — es también la que menos cambió de forma en la
  migración, porque ya estaba organizada internamente como si fuera un feature.
