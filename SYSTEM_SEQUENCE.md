# Diagrama de Secuencia del Sistema

Este documento detalla las interacciones técnicas, llamadas a la API y el orden temporal de los eventos entre los componentes de **AUTOnomIA**. Hay dos flujos de entrada distintos según si el visitante trae invitación (QR/PIN generado desde la app) o no.

```mermaid
sequenceDiagram
    autonumber
    actor V as Visitante
    participant K as Kiosko (Flutter)
    participant B as Backend (Go API)
    participant DB as PostgreSQL
    participant P as Persona (app residente/kigo-app)

    Note over V, K: Con invitación (QR/PIN)
    V->>K: Escanea QR en pantalla de entrada
    K->>B: GET /api/v1/kioskos/:id/invitaciones/validar?token=...
    B->>DB: Valida token, expiración, usos restantes
    B-->>K: Titular y casa destino de la invitación
    K->>K: Captura las evidencias que exija la config del kiosko (INE/rostro/placa)
    K->>B: POST /api/v1/kioskos/:id/invitaciones/:token/usar
    B->>DB: Crea Visita ya en estado APROBADO, marca el token consumido
    B-->>K: Visita aprobada
    K->>V: Muestra mensaje de bienvenida

    Note over V, K: Sin invitación (registro completo en el kiosko)
    V->>K: Inicia registro (toca pantalla)
    K->>K: Escaneo de INE (MLKit OCR local)
    K->>K: Validación de rostro (MLKit Face local)
    K->>B: POST /api/v1/kioskos/:id/visitas/
    B->>DB: Guarda la Visita en estado PENDIENTE

    Note over B, P: Notificación y autorización
    B->>P: Notificación push (FCM)
    P->>B: GET /api/v1/personas/me/visitas/pendientes

    alt Aprueba el residente
        rect rgba(0, 255, 0, 0.05)
            P->>B: PATCH /api/v1/personas/me/visitas/:id/estado {"estado":"APROBADO"}
            B->>DB: Actualiza estado a APROBADO
        end
    else Rechaza el residente
        rect rgba(255, 0, 0, 0.05)
            P->>B: PATCH /api/v1/personas/me/visitas/:id/estado {"estado":"RECHAZADO"}
            B->>DB: Actualiza estado a RECHAZADO
        end
    end

    Note over K: El kiosko hace polling del estado (GET /api/v1/kioskos/:id/visitas/:visitaId)
    K->>V: Muestra aprobado/rechazado en pantalla

    Note over K, V: La apertura física (torniquete/chapa) sigue siendo manual — el relay del hardware existe pero todavía nadie lo dispara automáticamente al aprobar.
```

El dashboard de admin puede resolver la misma visita con `PATCH /api/v1/visitas/:id/estado` (fuera de este diagrama, mismo efecto que la respuesta del residente).
