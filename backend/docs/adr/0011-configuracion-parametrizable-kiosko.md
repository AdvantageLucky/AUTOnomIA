# ADR-0011: Configuración parametrizable por kiosko

**Estado:** Aceptado  
**Fecha:** 2026-07-17

## Contexto

Cada kiosko (kiosko físico) puede tener requerimientos distintos: un edificio con seguridad alta puede pedir INE + foto de rostro a todos, mientras que un fraccionamiento informal solo pide foto de placa. La configuración debe vivir en el backend para que el kiosko la descargue al iniciar sesión, y debe ser editable desde el dashboard sin reiniciar el proceso.

Adicionalmente, el tiempo de espera antes de auto-rechazar una solicitud puede necesitar ser ajustado por cada residente individualmente (un residente con horario nocturno prefiere 10 minutos, otro prefiere 2). La prioridad es: `ResidenteConfig.tiempo_espera_min` → `KioskoConfig.tiempo_espera_min`.

## Decisión

### Modelo `KioskoConfig` (1:1 con `Kiosko`)

```go
type KioskoConfig struct {
    gorm.Model
    KioskoID uint `gorm:"uniqueIndex;not null"`

    // Apariencia del kiosko
    ColorKiosko  string `gorm:"default:'oscuro'"` // "claro" | "oscuro"
    IdiomaKiosko string `gorm:"default:'es'"`     // "es" | "en"

    // Bitácora para visitantes inesperados
    FotoPlacaVisitante  bool `gorm:"default:false"`
    FotoRostroVisitante bool `gorm:"default:true"`
    FotoIneVisitante    bool `gorm:"default:true"`

    // Bitácora para invitados con QR
    FotoPlacaInvitado  bool `gorm:"default:false"`
    FotoRostroInvitado bool `gorm:"default:false"`
    FotoIneInvitado    bool `gorm:"default:false"`

    // Comportamiento de solicitudes
    TiempoEsperaMin int    `gorm:"default:5"`  // minutos antes de auto-rechazar
    HorarioInicio   string `gorm:"default:'00:00'"` // "HH:MM"
    HorarioFin      string `gorm:"default:'23:59'"`
    MensajeBienvenida string

    Kiosko Kiosko `gorm:"foreignKey:KioskoID"`
}

func (KioskoConfig) TableName() string { return "kiosko_configs" }
```

### Campo adicional en `Residente`

```go
TiempoEsperaMin *int // nil = usar el del kiosko
```

### API

- `GET  /api/v1/kioskos/:id/config` — devuelve la config del kiosko (requiere JWT admin)
- `PATCH /api/v1/kioskos/:id/config` — actualiza uno o más campos (requiere JWT admin)
- El kiosko descarga su config al iniciar sesión con `GET /api/v1/kioskos/:id/config` (requiere sesión de kiosko)

### Migración

Nueva tabla `kiosko_configs` + columna `tiempo_espera_min` nullable en `residentes`. Al crear un `Kiosko`, se crea su `KioskoConfig` con defaults automáticamente (hook `AfterCreate` o service layer).

## Consecuencias

- El dashboard puede editar la config sin tocar el kiosko; el kiosko la relee al próximo ciclo de autenticación.
- El residente puede sobreescribir solo `tiempo_espera_min`; el resto de configs son del administrador.
- Los defaults son conservadores (pedir INE + rostro a visitantes, nada adicional a invitados con QR).
