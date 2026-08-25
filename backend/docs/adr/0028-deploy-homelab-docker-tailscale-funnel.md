# ADR-0028: Backend en Docker sobre un homelab, expuesto por Tailscale Funnel

**Estado:** Aceptado
**Fecha:** 2026-08-24

## Contexto

El backend necesitaba correr en algún lugar alcanzable por los kioskos, la
app Kigo y el dashboard durante FEPRO. No hay presupuesto para un proveedor
cloud, pero sí un homelab disponible (ThinkCentre M720q, i3-8100T, 7.6GB RAM,
sin GPU) — suficiente para Postgres + el backend Go, ninguno de los dos
particularmente pesado.

El LLM (resúmenes de visitas, `llama-server`) es harina de otro costal: sin
GPU, el homelab lo corre pero lento — no cabe en la misma máquina si se quiere
que responda rápido. Se resolvió aparte (ver más abajo) corriéndolo en una
laptop con GPU distinta, conectada por la misma red Tailscale.

Exponer el backend al internet público sin abrir puertos en el router, sin
IP fija, y sin certificados que gestionar a mano, apuntaba directo a
Tailscale, que el equipo ya usaba para otras cosas.

## Decisión

**Backend + Postgres en `docker-compose` en el homelab; expuesto a internet
por Tailscale Funnel en el puerto 10000, mapeado internamente al 8080 del
contenedor.**

1. Dockerfile multi-stage: compila con `golang:1.26-bookworm`, imagen final
   `debian:bookworm-slim` con el binario + `migrations/` + `web/admin/` — sin
   `llama.cpp/` (5.8GB, vendorizado aparte, nunca debe entrar al build
   context; ver `.dockerignore`).
2. Postgres y backend son servicios separados con volúmenes con nombre
   (`db_data`, `uploads_data`) — sobreviven a un `docker compose up --build`.
3. **El puerto público es 10000, no el 8080 nativo del backend.** Tailscale
   Funnel solo permite exponer 443, 8443 o 10000 al internet — el 8443 del
   homelab ya estaba en uso para otra cosa. El mapeo de Docker
   (`10000:8080`) existe únicamente para calzar con esa restricción, no
   porque el backend use ese puerto por sí mismo.
4. Funnel expone siempre en el 443 estándar de cara a internet
   (`https://homelab.tail8dc7f1.ts.net`, sin puerto en la URL) — el `10000`
   que se le pasa a `tailscale funnel` es el puerto *local* al que reenvía,
   no el público. Tailscale gestiona el certificado TLS automáticamente.
5. Todos los secretos (contraseña de DB, JWT, credenciales de Firebase/OAuth)
   viven en un `.env` fuera del repo, montado o leído directo en el homelab —
   nunca en la imagen ni en git. Las credenciales tipo archivo (Firebase
   Admin SDK) se montan como volumen de solo lectura, no como variable de
   entorno con el contenido completo.
6. El LLM se resolvió aparte: en vez de forzarlo al homelab sin GPU,
   `LLM_URL` apunta a `llama-server` corriendo en una laptop con GPU
   (RTX 2050), alcanzable por la misma red Tailscale — cero cambios de
   código, el backend nunca supo la diferencia.

## Consecuencias

- Redesplegar es `git pull && docker compose up -d --build` — sin pasos
  manuales adicionales, reproducible.
- El puerto 10000 en el compose es una decisión externa (impuesta por
  Funnel), no una preferencia del proyecto — si algún día se monta detrás de
  un proxy inverso propio o un balanceador con IP fija, ese mapeo puede
  volver al 8080 estándar sin tocar el Dockerfile.
- El backend queda expuesto al internet público completo, incluyendo el
  login del dashboard admin — decisión consciente para esta etapa (facilita
  que kioskos y apps fuera de la red local lo alcancen sin VPN), revisitable
  si el proyecto pasa a producción real.
- Separar el LLM del backend en máquinas distintas significa que un reinicio
  o caída de la laptop de GPU no tumba el backend — solo degrada los
  resúmenes (que ya toleran fallar, ver `visitas/llm.go`).
