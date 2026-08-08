package tenant

import "gorm.io/gorm"

// CentroHabitacional representa el tenant (fraccionamiento) en el sistema multi-tenant.
type CentroHabitacional struct {
	gorm.Model
	Nombre      string `gorm:"not null"`
	Direccion   string `gorm:"not null;default:''"`
	Codigo      string `gorm:"uniqueIndex"`
	Tipo        string `gorm:"not null;default:'habitacional'"`
	Descripcion string `gorm:"not null;default:''"`
}

func (CentroHabitacional) TableName() string {
	return "centros_habitacionales"
}
