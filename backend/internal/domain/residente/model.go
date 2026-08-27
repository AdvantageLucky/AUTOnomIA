package residente

import "gorm.io/gorm"

// Residente es un habitante del fraccionamiento que puede aprobar o rechazar visitas
// que lleguen a su casa/departamento a través del kiosko.
type Residente struct {
	gorm.Model
	TenantID        uint   `gorm:"column:tenant_id;not null;index"`
	Nombre          string `gorm:"not null"`
	ApellidoPaterno string `gorm:"not null"`
	ApellidoMaterno string `gorm:"not null"`
	Pin             string `gorm:"not null"`
	CasaDestino     string `gorm:"not null"`
	Telefono        string
	KioskoID        *uint
	TiempoEsperaMin *int
	Status          string     `gorm:"not null;default:'activo'"`
	FotoCaraUrl     string
	Embedding       FloatArray `gorm:"type:float[]"`
	DeviceToken     *string
}

func (Residente) TableName() string { return "residentes" }
