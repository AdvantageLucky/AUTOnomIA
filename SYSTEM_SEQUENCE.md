# Diagrama de Secuencia del Sistema

Este documento detalla las interacciones técnicas, llamadas a la API y el orden temporal de los eventos entre los componentes de **AUTOnomIA** durante el registro de un visitante.

```mermaid
sequenceDiagram
    autonumber
    actor V as Visitante
    participant K as Kiosko (Flutter)
    participant B as Backend (Go API)
    participant DB as PostgreSQL
    participant R as Residente (Flutter)

    Note over V, K: Flujo de Registro Autónomo
    V->>K: Inicia registro (Toca pantalla)
    K->>K: Escaneo INE (MLKit OCR local)
    K->>K: Validación Rostro (MLKit Face local)
    
    K->>B: POST /api/v1/accesos/:id/visitantes/
    B->>DB: Guarda datos preliminares y fotos
    
    Note over B, R: Notificación y Autorización
    B->>R: Envía notificación push / WebSocket
    R-->>B: GET /api/v1/visitas/pendientes (Revisa solicitud)
    
    alt ✅ APRUEBA ACCESO
        rect rgba(0, 255, 0, 0.05)
            R->>B: POST /api/v1/visitas/:id/aprobar
            B->>DB: Actualiza estado a "Aprobado"
            B->>K: Confirma acceso permitido (Abre pluma)
            K->>V: Muestra mensaje de Bienvenida
        end
    else ❌ RECHAZA ACCESO
        rect rgba(255, 0, 0, 0.05)
            R->>B: POST /api/v1/visitas/:id/rechazar
            B->>DB: Actualiza estado a "Rechazado"
            B->>K: Deniega acceso
            K->>V: Muestra mensaje de Rechazo
        end
    end
