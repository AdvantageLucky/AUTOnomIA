# ADR-0029: FCM real, con caída automática al notificador falso si falla

**Estado:** Aceptado
**Fecha:** 2026-08-24

## Contexto

`PushNotificador` (residente/miembro de casa recibe push cuando llega una
visita a aprobar) ya tenía su abstracción lista desde antes de este ADR:
interfaz `PushSender` + `LogPushSender` como implementación falsa, mientras no
existiera un proyecto de Firebase configurado. Ese proyecto ya existe
(`autonomia-6682c`), con la app Android registrada y la credencial de cuenta
de servicio disponible — tocaba conectar la implementación real.

## Decisión

**`FirebasePushSender` implementa `PushSender` con el SDK de Firebase Admin
para Go. El servidor decide entre él y `LogPushSender` según haya o no una
credencial configurada — nunca deja de arrancar por esto.**

1. `FIREBASE_CREDENTIALS_PATH` apunta al JSON de cuenta de servicio
   (Firebase Console → Configuración del proyecto → Cuentas de servicio →
   Generar nueva clave privada). Vacío o si `NewFirebasePushSender` falla al
   inicializar → cae a `LogPushSender{}` con un log de aviso, en vez de
   `log.Fatal`. Un ambiente de desarrollo sin FCM configurado no debe
   tumbarse por esto.
2. La credencial nunca viaja como valor de variable de entorno ni al repo —
   se monta como archivo de solo lectura en el contenedor (ver ADR-0028) y el
   `.gitignore` raíz la bloquea por patrón (`*firebase-adminsdk*.json`)
   independientemente de dónde se coloque dentro de `backend/`.
3. Client SDK (`firebase_core`/`firebase_messaging`) se agrega a la app Kigo
   sin `firebase_options.dart` — en Android basta con el `google-services.json`
   ya procesado por el plugin de Gradle (`com.google.gms.google-services`);
   ese archivo solo es necesario para web o multi-plataforma explícita.
4. Se descartó declarar las dependencias nativas de Firebase a mano en
   `android/app/build.gradle.kts` junto con los paquetes Flutter — los
   paquetes ya traen sus propias dependencias nativas, declararlas dos veces
   desalinea versiones contra el BoM que ellos mismos gestionan.

## Consecuencias

- El registro del *device token* del residente (cuándo y cómo se guarda)
  sigue siendo el mismo mecanismo de antes de este ADR — no cambió.
- El notificador real depende de que `google-services.json` tenga el mismo
  `applicationId`/`namespace` que la app compilada — un desajuste ahí no
  falla en este código, falla en tiempo de build de Android (ver el bug real
  que esto causó al renombrar `residente/` → `kigo-app/`, corregido en el
  mismo lote de commits).
- Sin OTP por push (ver discusión aparte): FCM no puede sustituir el OTP de
  registro porque requiere que el dispositivo ya tenga la app instalada y ya
  esté registrado — el registro de teléfono es, por definición, el momento en
  que ese registro todavía no existe.
