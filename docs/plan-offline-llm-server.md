# Plan de Implementación: Modo Offline y Servidor LLM Local

Este documento detalla la arquitectura y pasos para la operación sin conexión a internet de los kioskos físicos y la integración del servidor de lenguaje local (LLM) mediante Tailscale.

---

## 1. Arquitectura del Modo Offline (Kiosko + Backend)

### Objetivo
Permitir que el Kiosko físico continúe validando accesos de residentes, escaneando QRs y registrando visitantes cuando se interrumpa la conexión de red local o a internet, sincronizando automáticamente cuando vuelva el servicio.

### Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────┐
│                       Kiosko (Flutter)                      │
│                                                             │
│  [ Validaciones Locales ]        [ Cola Outbox (SQLite) ]   │
│  • TFLite (Embeddings Rostro)    • Visitas sin internet     │
│  • PIN Residentes en hash        • Fotos temporales locales │
│  • Destinos en caché SQLite      • Status: synced = false   │
└─────────────────────────────────────────────────────────────┘
                               │
               (Cuando detecta red / Heartbeat)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend Go (Homelab)                    │
│                                                             │
│  • GET /api/v1/kioskos/:id/sync/snapshot                    │
│    (Descarga destinos, residentes y embeddings actualizados)│
│  • POST /api/v1/kioskos/:id/visitas/batch                   │
│    (Procesa visitas acumuladas con timestamps originales)   │
└─────────────────────────────────────────────────────────────┘
```

### Componentes en Kiosko (Flutter)
1. **Almacenamiento Local (SQLite via `sqflite`):**
   - Tabla `destinos`: Lista de calles y números activos.
   - Tabla `residentes`: Hash de PIN, datos básicos y vector facial de 192 floats.
   - Tabla `visitas_queue`: Registros tomados offline con campos JSON, rutas de fotos en almacenamiento local (`path_provider`) y marca `synced (0/1)`.
2. **Monitor de Conectividad (`ConnectivityService`):**
   - Uso de `connectivity_plus` y verificación periódica por ping HTTP a `/health`.
   - Modificación de variable de estado reactiva `isOffline`.
3. **Servicio de Sincronización (`SyncWorker`):**
   - Al reconectar: consume la cola `visitas_queue WHERE synced = 0`, envía peticiones en lote con fotos multipart y marca los registros sincronizados.

### Endpoints en Backend (Go)
- `GET /api/v1/kioskos/:id/sync/snapshot`: Entrega el paquete de datos para caché local.
- `POST /api/v1/kioskos/:id/visitas/batch`: Inserción masiva de visitas offline respetando `created_at` del evento.

---

## 2. Servidor LLM Local (`llama.cpp` + Tailscale)

### Objetivo
Aprovechar una máquina externa (PC con GPU bajo Debian) para ejecutar inferencia de LLM sin exponer puertos al internet público y sin requerir GPU en el homelab.

### Diagrama de Conexión

```
┌───────────────────────────┐                ┌───────────────────────────┐
│     PC Debian (con GPU)   │                │     Homelab (Docker)      │
│                           │                │                           │
│  • llama-server (:8081)   │ ◄───────────── │  • Backend Go             │
│  • Tailscale Serve HTTPS  │  Red Tailnet   │  • LLM_URL=https://...    │
│    (MagicDNS / Cert TLS)  │                │                           │
└───────────────────────────┘                └───────────────────────────┘
```

### Pasos de Despliegue

1. **Instalación de Tailscale en PC Debian:**
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

2. **Compilación y ejecución de `llama-server`:**
   ```bash
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp && cmake -B build && cmake --build build --config Release -j$(nproc)
   
   # Ejecución con modelo cuantificado (ej. Qwen2.5-7B-Instruct o Llama-3.2-3B en formato GGUF)
   ./build/bin/llama-server \
     -m ./models/qwen2.5-7b-instruct-q4_k_m.gguf \
     -c 2048 \
     --port 8081 \
     --host 127.0.0.1
   ```

3. **Exposición interna en la Tailnet:**
   ```bash
   tailscale serve https / http://127.0.0.1:8081
   ```

4. **Configuración en el Homelab (`backend/.env`):**
   ```env
   LLM_URL=https://debian-gpu.tu-tailnet.ts.net
   ```
   Reiniciar servicio con `docker compose up -d`.
