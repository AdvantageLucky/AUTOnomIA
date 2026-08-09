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

**MVVM con Provider** (`ChangeNotifier`), con navegación por rutas nombradas declaradas en
`main.dart`.

```
lib/
├── l10n/            AppLocalizations — i18n español/inglés
├── models/          InvitationModel
├── services/        ApiService (HTTP + JWT), RegistroService (alta pública)
├── theme/           AppTheme — tokens de diseño
├── viewmodels/      auth, invitation, registro, settings, user
└── views/           splash, login, registro, registro_estado, dashboard,
                     generate_qr, my_invitations, settings, recovery_password
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
