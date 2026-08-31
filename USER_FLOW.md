# Flujo de Usuario y Lógica de Negocio

Este documento ilustra el mapa de decisiones y la experiencia paso a paso dentro de **AUTOnomIA**. El punto de entrada real es la pantalla de escaneo de QR del kiosko — de ahí se bifurca según si el visitante trae invitación o no.

```mermaid
flowchart TD
    Inicio([Visitante llega a la caseta]) --> Q1{¿Trae QR/invitación?}

    Q1 -- Sí --> Q2[Escanea QR en el kiosko]
    subgraph Con invitación
        Q2 --> Q3[Backend valida el token]
        Q3 --> Q4{¿La config del kiosko exige evidencia?}
        Q4 -- Sí --> Q5[Captura INE/rostro/placa según la config]
        Q4 -- No --> Q6
        Q5 --> Q6[Consume el token: Visita queda APROBADA de inmediato]
    end
    Q6 --> Fin1([Mensaje de bienvenida en el kiosko])

    Q1 -- No --> K1[Toca "No tengo QR" / registro completo]
    subgraph App Kiosko sin invitación [Procesamiento On-Device]
        K1 --> K2[Escanea INE]
        K2 --> K3[Extrae CURP y nombre con OCR / MLKit]
        K3 --> K4[Captura foto del visitante]
        K4 --> K5[Valida rostro / MLKit Face]
        K5 --> K6[Confirma datos y casa destino en pantalla]
    end

    K6 -->|POST /kioskos/:id/visitas/| B1

    subgraph API Go [Backend]
        B1[Recibe la solicitud] --> B2[(Guarda Visita en estado PENDIENTE)]
        B2 --> B3[Envía notificación push FCM]
    end

    B3 --> R1

    subgraph App Residente kigo-app [Teléfono del destino]
        R1[Recibe la notificación y abre la app] --> R2{¿Aprueba la visita?}
    end

    R2 -- Sí --> API_App[PATCH /personas/me/visitas/:id/estado APROBADO]
    R2 -- No --> API_Rec[PATCH /personas/me/visitas/:id/estado RECHAZADO]

    API_App --> K_Fin1([Kiosko muestra Aprobado en pantalla])
    API_Rec --> K_Fin2([Kiosko muestra Rechazado en pantalla])

    K_Fin1 -.-> Manual([Apertura física del torniquete/chapa: manual todavía — el relay existe pero nadie lo dispara automático])
```

Notas sobre el estado real del sistema (para no repetir el desfase que tenía este documento antes):

- El actor "Residente" como modelo separado no existe — la identidad del lado del destino es `Persona` (teléfono + OTP), unida a un `CentroHabitacional` vía `Membresia`.
- El admin del dashboard puede resolver la misma visita desde su propia pantalla (`PATCH /visitas/:id/estado`), en paralelo a que el residente lo haga desde kigo-app.
- El kiosko del lado del visitante hace *polling* del estado de la visita — no hay WebSocket hacia el kiosko.
