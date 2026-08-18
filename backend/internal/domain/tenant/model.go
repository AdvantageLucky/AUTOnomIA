package tenant

import "gorm.io/gorm"

// CentroHabitacional representa el tenant (fraccionamiento) en el sistema multi-tenant.
type CentroHabitacional struct {
	gorm.Model
	Nombre    string `gorm:"not null"`
	Direccion string `gorm:"not null;default:''"`
	// Codigo es *string (no string) porque un tenant recién creado no tiene
	// código todavía — el admin lo asigna después desde el dashboard. Con un
	// string vacío por defecto, el segundo admin que se registra colisiona
	// contra el uniqueIndex (Postgres solo trata NULL, no "", como distinto
	// de sí mismo en una constraint única).
	Codigo      *string `gorm:"uniqueIndex"`
	Tipo        string  `gorm:"not null;default:'habitacional'"`
	Descripcion string  `gorm:"not null;default:''"`
}

func (CentroHabitacional) TableName() string {
	return "centros_habitacionales"
}
