// backend/internal/domain/residente/membresia_model.go
package residente

import "gorm.io/gorm"

const (
	MembresiaRolTitular  = "titular"
	MembresiaRolFamiliar = "familiar"

	// Reusadas por Membresia.Status (y antes por Residente.Status, ya
	// eliminado) — el ciclo de aprobación activo/pendiente/rechazado es el
	// mismo para ambos.
	ResidenteStatusActivo    = "activo"
	ResidenteStatusPendiente = "pendiente"
	ResidenteStatusRechazado = "rechazado"
)

// Membresia es la relación de una Persona (internal/domain/persona) con un
// tenant específico — reemplaza lo que hoy vive dentro de Residente (nombre,
// teléfono y embedding se mueven a Persona; casa_destino, pin y rol se
// quedan aquí, porque son propios de cada centro habitacional). Ver spec
// 2026-08-16-persona-identidad-kigo-design.md §2.
//
// Status reusa las constantes ResidenteStatus* de arriba (activo |
// pendiente | rechazado) — el ciclo de aprobación es el mismo.
type Membresia struct {
	gorm.Model
	PersonaID                   uint   `gorm:"column:persona_id;not null;index"`
	TenantID                    uint   `gorm:"column:tenant_id;not null;index"`
	CasaDestino                 string `gorm:"not null"`
	Pin                         string `gorm:"not null"`
	Rol                         string `gorm:"not null;default:'titular'"`
	Status                      string `gorm:"not null;default:'activo'"`
	PermiteReconocimientoFacial bool   `gorm:"not null;default:false"`
	KioskoID                    *uint
	TiempoEsperaMin             *int
}

func (Membresia) TableName() string { return "membresias" }
