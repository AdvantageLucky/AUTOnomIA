# Flujo de Usuario y Lógica de Negocio

Este documento ilustra el mapa de decisiones y la experiencia paso a paso que sigue un visitante y un residente dentro de **AUTOnomIA**.

```mermaid
flowchart TD
    Inicio([Visitante llega a la caseta]) --> K1[Toca la pantalla del Kiosko]
    
    subgraph App Kiosko [Procesamiento On-Device]
        K1 --> K2[Escanea INE]
        K2 --> K3[Extrae datos con OCR / MLKit]
        K3 --> K4[Captura foto del visitante]
        K4 --> K5[Valida rostro / MLKit Face]
        K5 --> K6[Confirma datos en pantalla]
    end
    
    K6 -->|Envía datos| B1
    
    subgraph API Go [Backend]
        B1[Recibe solicitud de acceso] --> B2[(Guarda estado Pendiente en BD)]
        B2 --> B3[Dispara Notificación]
    end
    
    B3 --> R1
    
    subgraph App Residente [Teléfono del Destino]
        R1[Recibe alerta y abre app] --> R2{¿Aprueba la visita?}
    end
    
    R2 -- Sí --> API_App[Backend actualiza a Aprobado]
    R2 -- No --> API_Rec[Backend actualiza a Rechazado]
    
    API_App --> K_Fin1([Abre pluma / Mensaje de Bienvenida])
    API_Rec --> K_Fin2([Deniega acceso / Mensaje de Rechazo])
