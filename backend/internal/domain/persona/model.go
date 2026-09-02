package persona

import (
	"time"

	"kigo-autonomia-backend/internal/domain/residente"

	"gorm.io/gorm"
)

// Persona es la identidad Kigo global, ancla en el teléfono — vive fuera de
// cualquier tenant a propósito: el enrolamiento facial cross-centro necesita
// una identidad por encima del aislamiento por tenant_id (ver spec
// 2026-08-16-persona-identidad-kigo-design.md §2).
type Persona struct {
	gorm.Model
	Telefono             string `gorm:"not null;uniqueIndex"`
	TelefonoVerificadoAt *time.Time
	Nombre               string               `gorm:"not null;default:''"`
	ApellidoPaterno      string               `gorm:"not null;default:''"`
	ApellidoMaterno      string               `gorm:"not null;default:''"`
	Embedding            residente.FloatArray `gorm:"type:float[]"`
	FotoCaraUrl          string
	Curp                 string `gorm:"not null;default:''"`
	FotoIneUrl           string
	DeviceToken          *string
	// KigoUserID vincula esta Persona con su cuenta en Kigo Parkimovil --
	// la mini-app del marketplace solo recibe este id (via kigo.auth.init()),
	// nunca teléfono ni nombre, así que es la única clave que tiene para
	// resolver "¿ya estás registrado en AUTOnomIA?".
	KigoUserID *string `gorm:"uniqueIndex"`
}

func (Persona) TableName() string { return "personas" }
