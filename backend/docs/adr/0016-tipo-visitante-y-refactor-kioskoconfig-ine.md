# ADR-0016: TipoVisitante y refactor de campos INE en KioskoConfig

**Estado:** Aceptado  
**Fecha:** 2026-07-30  
**Supercede parcialmente:** ADR-0011 (sección de campos `FotoIne*`)

## Contexto

El modelo original de `KioskoConfig` trataba la captura de INE como un toggle configurable por kiosko, tanto para visitantes sin invitación (`FotoIneVisitante`) como con invitación (`FotoIneInvitado`). Esto generó dos problemas:

1. **Visitantes sin invitación:** La CURP y clave de elector son la única forma de identificar a un visitante recurrente y construir su historial. Desactivar la INE equivale a desactivar las búsquedas por persona, el análisis de anomalías y el autopass. No tiene sentido que sea opcional.

2. **Visitantes con invitación:** El modelo de invitación (futuro) incluirá el titular en el token, por lo que la identidad ya está garantizada por el backend. La INE puede ser un refuerzo de seguridad configurable, pero no el identificador primario.

Además, el backend no tenía forma de distinguir en el request si quien llega es un visitante inesperado o alguien con invitación, lo que impedía aplicar reglas de validación distintas.

## Decisión

### 1. `FotoIneVisitante` se elimina de `KioskoConfig`

Para visitantes sin invitación (`TipoVisitante = VISITANTE`), la INE siempre es obligatoria. La lógica de `validarCamposCondicionales` en `validation.go` fija `reqIne = true` para este caso sin consultar la config.

### 2. `FotoIneInvitado` se reemplaza por `IneObligatorioInvitado`

El nuevo campo es semánticamente más preciso: no habla de "foto de INE" sino de si el documento de identidad es obligatorio para invitados. Por defecto es `false` (el token de invitación es suficiente identificación).

```go
// KioskoConfig — campos de bitácora por tipo de visitante
FotoPlacaVisitante  bool `gorm:"not null;default:false"`
FotoRostroVisitante bool `gorm:"not null;default:true"`
// INE siempre requerida para visitante sin invitación (ver validation.go)

FotoPlacaInvitado      bool `gorm:"not null;default:false"`
FotoRostroInvitado     bool `gorm:"not null;default:false"`
IneObligatorioInvitado bool `gorm:"not null;default:false"`
```

### 3. Se añade `TipoVisitante` al modelo `Visita` y al request del kiosko

```go
type TipoVisitante string

const (
    TipoSinInvitacion TipoVisitante = "VISITANTE"
    TipoConInvitacion TipoVisitante = "INVITADO"
)
```

El kiosko manda `tipo_visitante` en el form-data. El handler obtiene la `KioskoConfig` y delega la validación condicional a `validarCamposCondicionales(req, cfg)`.

### 4. Validación condicional en el handler, no en el binding

Los campos `ClaveLector`, `Curp`, `FotoDocumento`, `FotoRostro` y `Placa` no llevan `binding:"required"`. La validación se hace manualmente post-bind según la combinación `TipoVisitante` × config:

| Campo | VISITANTE | INVITADO |
|---|---|---|
| INE (tipo_doc + curp + foto_doc) | siempre | si `IneObligatorioInvitado` |
| Foto rostro | si `FotoRostroVisitante` | si `FotoRostroInvitado` |
| Placa + foto placa | si `FotoPlacaVisitante` | si `FotoPlacaInvitado` |

## Consecuencias

- El historial por CURP y el análisis de anomalías siguen funcionando para todos los visitantes sin invitación.
- El flujo de invitados (futuro) puede operar sin documento si el centro habitacional no lo exige.
- La config del kiosko es más simple: ya no hay toggles redundantes para un campo que nunca debería desactivarse.
- Requiere migración 000019 (`DROP foto_ine_visitante`, `DROP foto_ine_invitado`, `ADD ine_obligatorio_invitado`) y migración 000018 (`ADD tipo_visitante` en `visitas`).
