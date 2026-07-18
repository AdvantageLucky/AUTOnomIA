# 0009 - Google OAuth para el dashboard admin sin bundler ni backend de sesión

## Status
Accepted

## Context
El dashboard admin es un SPA escrito en HTML + CSS + JS vanilla, servido directamente por el
backend Go como archivos estáticos. No hay Node.js, no hay bundler (webpack, vite), y no se quiere
agregar uno — el dashboard es una herramienta interna simple y la complejidad de un toolchain de
frontend no está justificada (ver [0001](0001-stack-tecnologico.md)).

El admin necesita una opción de login con Google para reducir la fricción de credenciales. Las
alternativas evaluadas fueron:

- **Redireccion OAuth estándar (Authorization Code Flow)**: requiere guardar el `state` anti-CSRF
  en sesión del backend y manejar el redirect a `/auth/callback` — agrega estado de sesión al
  backend que actualmente es stateless.
- **JWT de Google (GSI one-tap)**: el browser recibe el `id_token` firmado por Google directamente
  como un JWT en el callback del frontend. El backend solo necesita verificar ese JWT contra la
  clave pública de Google.

## Decision
Usar **Google Identity Services (GSI)** con el flujo de `credential` (id_token en el cliente):

1. El HTML carga `https://accounts.google.com/gsi/client` como script externo.
2. `google.accounts.id.initialize({ client_id, callback })` inicializa el botón one-tap.
3. El callback recibe `{ credential }` — un JWT firmado por Google.
4. El frontend hace `POST /auth/google` con `{ credential }` al backend.
5. El backend llama a `GET https://oauth2.googleapis.com/tokeninfo?id_token=<credential>` para
   verificar el token con Google sin necesidad de descargar las claves públicas y manejar la
   rotación localmente.
6. Si el `email` del token info corresponde a un `Admin` en base de datos, se emite un JWT del
   sistema con las mismas claims que el login por contraseña.

El `GOOGLE_CLIENT_ID` se inyecta como variable de entorno en el backend, que lo expone al
frontend a través de un endpoint `GET /auth/google/config` o como variable en el HTML
(`window.__GOOGLE_CLIENT_ID__`). El backend usa `os.Getenv("GOOGLE_CLIENT_ID")` para leerlo.

## Consequences
- El backend sigue siendo stateless respecto a la sesión OAuth — no guarda `state`, no tiene
  callback route, no maneja refresh tokens de Google.
- Verificar el `id_token` con `tokeninfo` implica una llamada HTTP síncrona a Google en cada
  login con Google. Es aceptable para logins (evento poco frecuente); no sería aceptable para
  cada request.
- Solo los emails que ya existen como `Admin` en la base de datos pueden loguearse con Google —
  Google OAuth no crea admins automáticamente. El admin debe ser creado primero por otro admin
  (con email + contraseña) y luego puede usar Google signin.
- Si Google cambia la API `tokeninfo` o la depreca, el mecanismo de verificación debe actualizarse.
  La alternativa robusta es verificar el JWT localmente con las claves públicas de Google
  (`https://www.googleapis.com/oauth2/v3/certs`), pero agrega complejidad de rotación de claves.
- El script GSI es una dependencia de tercero cargada en runtime — si hay restricciones de red
  (entorno sin internet), el botón de Google no aparecerá. El login por contraseña sigue siendo
  el fallback.
