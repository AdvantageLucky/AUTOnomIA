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
}

func (Persona) TableName() string { return "personas" }
