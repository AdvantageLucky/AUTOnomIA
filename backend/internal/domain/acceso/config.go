package acceso

import "gorm.io/gorm"

// AccesoConfig almacena la configuración parametrizable de un kiosko.
// Relación 1:1 con Acceso; se crea con defaults al crear el Acceso.
type AccesoConfig struct {
	gorm.Model
	AccesoID uint `gorm:"uniqueIndex;not null"`

	// Apariencia del kiosko físico
	ColorKiosko  string `gorm:"not null;default:'oscuro'"` // "claro" | "oscuro"
	IdiomaKiosko string `gorm:"not null;default:'es'"`     // "es" | "en"

	// Bitácora para visitantes inesperados (sin invitación)
	FotoPlacaVisitante  bool `gorm:"not null;default:false"`
	FotoRostroVisitante bool `gorm:"not null;default:true"`
	FotoIneVisitante    bool `gorm:"not null;default:true"`

	// Bitácora para invitados con QR
	FotoPlacaInvitado  bool `gorm:"not null;default:false"`
	FotoRostroInvitado bool `gorm:"not null;default:false"`
	FotoIneInvitado    bool `gorm:"not null;default:false"`

	// Comportamiento de solicitudes
	TiempoEsperaMin   int    `gorm:"not null;default:5"` // minutos antes de auto-rechazar
	HorarioInicio      string `gorm:"not null;default:'00:00'"`
	HorarioFin         string `gorm:"not null;default:'23:59'"`
	MensajeBienvenida  string
}

func (AccesoConfig) TableName() string { return "acceso_configs" }
