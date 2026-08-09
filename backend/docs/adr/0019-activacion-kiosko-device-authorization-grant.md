# 0019 - Activación de kioskos con Device Authorization Grant (RFC 8628)

## Status
Accepted (reemplaza a [0005](0005-generacion-clave-kiosko.md))

## Context
[0005](0005-generacion-clave-kiosko.md) definió que el administrador registra el kiosko desde el
panel, el servidor devuelve `id` + `ClaveKiosko` en texto plano una sola vez, y el admin transcribe
ambos datos al dispositivo para activarlo.

En operación ese flujo tiene varios problemas:

- La `ClaveKiosko` es una cadena aleatoria de 16 caracteres. Transcribirla a mano en la pantalla
  táctil de un kiosko es lento y propenso a error; el admin termina fotografiándola o enviándosela
  por mensaje, lo que la expone en canales que no controlamos.
- El servidor no tiene forma de saber *qué dispositivo físico* se está activando. Quien tenga la
  clave puede levantar una sesión desde cualquier lado.
- La clave queda visible en el dashboard hasta que el admin cierra el modal, y si no la copió a
  tiempo el kiosko queda inservible y hay que recrearlo.
- El sentido del flujo es incómodo: el dispositivo desatendido —el que peor teclado tiene— es el
  que debe recibir el secreto largo.

## Decision
Implementar el **OAuth 2.0 Device Authorization Grant** ([RFC 8628](https://datatracker.ietf.org/doc/html/rfc8628))
invirtiendo la dirección del flujo: el kiosko genera un código corto y el admin lo transcribe en el
dashboard, que es donde hay teclado real.

Nueva tabla `device_authorizations` con estados `pending` / `approved` / `denied`.

1. El kiosko llama `POST /auth/device/authorize` (público, sin autenticación) y recibe:
   `device_code` (32 bytes hex), `user_code` (formato `XXXX-XXXX`), `verification_uri`,
   `expires_in` (15 min) e `interval` (5 s).
2. El kiosko muestra el `user_code` en pantalla junto a un QR con la `verification_uri`, y hace
   *polling* a `POST /auth/device/token` con
   `grant_type = urn:ietf:params:oauth:grant-type:device_code`. Mientras no haya aprobación el
   servidor responde `authorization_pending`.
3. El admin, ya autenticado en el dashboard, valida el código con
   `GET /device/validar?user_code=...`, crea el kiosko y lo vincula con
   `POST /device/:user_code/aprobar`.
4. En el siguiente *poll* el kiosko recibe su token de sesión persistida, su `kiosko_id` y la
   `clave_kiosko`, y la autorización se marca como consumida (*soft-delete*).

El `user_code` se genera con el charset `BCDFGHJKLMNPQRSTVWXZ` —sin vocales— para que no puedan
formarse palabras accidentales, y sin caracteres ambiguos al leerlos en pantalla.

La `ClaveKiosko` de [0005](0005-generacion-clave-kiosko.md) **no desaparece**: sobrevive como
credencial interna que el kiosko guarda en almacenamiento seguro y usa para re-autenticarse en
silencio cuando su token de sesión deja de ser válido. Lo que queda reemplazado es su *transcripción
manual*: ya no se muestra al admin ni se copia a mano.

## Consequences
- El admin nunca ve ni copia una clave. El modal de alta pasa a ser un asistente de tres pasos:
  código de activación → datos del kiosko → configuración inicial.
- El `user_code` expira en 15 minutos y requiere aprobación explícita de un admin autenticado, así
  que un código filtrado tiene una ventana de uso corta y no basta por sí solo.
- `POST /auth/device/token` es público y hoy **no tiene rate limiting**. Adivinar un `device_code`
  de 32 bytes es impracticable, pero el endpoint admite *polling* ilimitado; conviene limitarlo
  antes de un despliegue real.
- El kiosko necesita conectividad en el primer arranque. Sin red no puede activarse, y la pantalla
  de activación es lo único que puede mostrar.
- La activación es revocable: al eliminar un kiosko el handler llama `RevokeAllByKioskoID`, el
  middleware `RequireKiosko` empieza a responder 401 y el dispositivo vuelve por sí solo a la
  pantalla de activación.
- Se añade una dependencia de QR en la app del kiosko para renderizar el código de verificación.
