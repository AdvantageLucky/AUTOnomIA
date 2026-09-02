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
	Descripcion string  `gorm:"not null;default:''"`
	// TelefonoContacto vivía antes por-kiosko (KioskoConfig) -- un mismo
	// centro con varios kioskos terminaba con un número distinto en cada
	// uno, sin ninguna razón real para variar. Un solo número por centro.
	TelefonoContacto string `gorm:"column:telefono_contacto;not null;default:''"`
}

func (CentroHabitacional) TableName() string {
	return "centros_habitacionales"
}
