package residente

import "gorm.io/gorm"

// Residente es un habitante del fraccionamiento que puede aprobar o rechazar visitas
// que lleguen a su casa/departamento a través del kiosko.
type Residente struct {
	gorm.Model
	TenantID        uint      `gorm:"column:tenant_id;not null;index"`
	Nombre          string    `gorm:"not null"`
	ApellidoPaterno string    `gorm:"not null"`
	ApellidoMaterno string    `gorm:"not null"`
	Pin             string    `gorm:"not null"` // bcrypt hash del PIN de 4-6 dígitos
	CasaDestino     string    `gorm:"not null"` // "Torre B, Depto 102" — coincide con Destino.Nombre
	Telefono        string
	KioskoID        *uint     `gorm:"index"` // nullable: auto-registros no tienen kiosko asignado
	TiempoEsperaMin *int      // nil = usar el del KioskoConfig del kiosko
	Status          string    `gorm:"not null;default:'activo'"` // pendiente | activo | rechazado
	FotoCaraUrl     string    // ruta relativa bajo /static/caras/
	Embedding       []float64 `gorm:"type:float[]"` // vector FaceNet 128-dim; nil hasta tener modelo
}

func (Residente) TableName() string { return "residentes" }

const (
	ResidenteStatusActivo    = "activo"
	ResidenteStatusPendiente = "pendiente"
	ResidenteStatusRechazado = "rechazado"
)
