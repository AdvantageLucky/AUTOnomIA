package persona

import (
	"time"

	"gorm.io/gorm"
)

// OtpSolicitud es un código de verificación pendiente para un teléfono —
// vive fuera de Persona porque una Persona todavía no existe hasta que el
// código se verifica (ver spec §3).
type OtpSolicitud struct {
	gorm.Model
	Telefono string    `gorm:"not null;index"`
	Codigo   string    `gorm:"not null"`
	ExpiraEn time.Time `gorm:"not null"`
	Intentos int       `gorm:"not null;default:0"`
}

func (OtpSolicitud) TableName() string { return "otp_solicitudes" }
