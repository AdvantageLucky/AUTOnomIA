# kigo_user

App Flutter para los **residentes** de una instalación gestionada con AUTOnomIA. Desde aquí un
residente se da de alta, genera invitaciones QR para sus visitas y consulta su historial.

## Comandos

```bash
flutter pub get          # instalar dependencias
flutter run              # correr en dispositivo/emulador conectado
flutter analyze          # análisis estático
flutter test             # tests
flutter build apk        # APK de release
```

## Alta y acceso

El residente **no depende de que el administrador lo dé de alta uno por uno**. El flujo es:

1. El administrador le comparte el **código público de la instalación** (ej. `FEPRO-2026`).
2. El residente abre la app → *Solicitar acceso*, escribe el código y la app confirma el nombre de
   la instalación.
3. Elige su casa **de la lista de destinos** registrados por el administrador —no la escribe a
   mano, para que coincida exactamente con la que usan las visitas—, define un PIN de 4–6 dígitos y
   toma una foto de su rostro.
4. La solicitud queda en estado `pendiente`. El administrador la aprueba o rechaza desde el
   dashboard.
5. Una vez aprobada, el residente entra con **código de instalación + casa + PIN**.

Ver [ADR 0020](../backend/docs/adr/0020-auto-registro-residente-por-codigo-instalacion.md).

## Arquitectura

**MVVM con Provider** (`ChangeNotifier`), organizado **por feature** — mismo criterio que el
kiosko y kiosko-salida (ver [ADR 0002 de kiosko](../kiosko/docs/ADR/0002-arquitectura-por-feature.md)
y [ADR 0009 de esta app](docs/ADR/0009-migracion-a-arquitectura-por-feature.md), que reemplaza a la
organización por tipo de archivo original). Navegación por rutas nombradas declaradas en `main.dart`.

```
lib/
├── core/                     Transversal a toda la app
│   ├── l10n/                 AppLocalizations — i18n español/inglés
│   ├── models/                membresia_model
│   ├── services/              ApiService (HTTP + JWT), PushService (FCM), DeepLinkServicio
│   ├── theme/                 AppTheme — tokens de diseño
│   ├── utils/                  constants, fechas
│   ├── viewmodels/            AuthViewModel (sesión + membresías), SettingsViewModel
│   └── widgets/                kigo_list_row, kigo_primary_button, kigo_text_field
└── features/
    ├── shell/                 KigoShell (bottom nav 3 pestañas), splash
    ├── onboarding/            teléfono+OTP, identidad (INE+rostro / Kigo Verify), unirse a centro
    ├── invitar/               crear invitaciones, Mis invitaciones, invitados frecuentes, Mi QR
    ├── solicitudes/           pendientes en tiempo real, historial de visitas, identidades y confianza
    ├── companeros_casa/       compañeros de la misma casa_destino
    └── settings/              ajustes y aviso de privacidad
```

### i18n

Los textos se resuelven con `AppLocalizations.t(context, 'clave')`. Las traducciones viven en un
mapa `_localizedValues` con las variantes `es` y `en`; si una clave falta en inglés cae a español, y
si no existe en ninguno se devuelve la propia clave (para detectarlo en pantalla).

### Autenticación

El login devuelve un **JWT de residente** (TTL 7 días) que `ApiService` adjunta en cada petición y
que se persiste con `shared_preferences`. Es distinto del token de sesión del kiosko y del JWT de
administrador: sus claims no sirven en rutas de admin.

## Sistema de diseño

Los tokens viven en `AppTheme` (`lib/theme/app_theme.dart`) y están alineados 1:1 con el dashboard
web y la app del kiosko: mismo naranja de marca, mismos fondos, misma tipografía (Space Grotesk).
Ver [ADR 0001 de producto](../docs/adr/0001-sistema-diseno-unificado.md).

## Notas de implementación

- Las subidas de imagen deben declarar el `Content-Type` explícitamente
  (`MediaType('image', 'jpeg')`): el paquete `http` de Dart envía `application/octet-stream` por
  defecto y el backend solo acepta `image/jpeg` e `image/png`.
- Los tests no instancian `ThemeData`, porque construirlo dispara la descarga de fuentes de
  `google_fonts`; verifican las constantes de color directamente.
