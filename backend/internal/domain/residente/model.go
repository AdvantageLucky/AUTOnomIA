/*
Package residente
DB Models

Model Residente
Residente: Represnta la tabla de residentes relacionados a un kiosko conteniendo la informacion de un residente
*/
package residente

import "gorm.io/gorm"

// Residente es un habitante del fraccionamiento que puede aprobar o rechazar visitas
// que lleguen a su casa/departamento a través del kiosko.
type Residente struct {
	gorm.Model
	Nombre          string `gorm:"not null"`
	ApellidoPaterno string `gorm:"not null"`
	ApellidoMaterno string `gorm:"not null"`
	Pin             string `gorm:"not null"` // bcrypt hash del PIN de 4-6 dígitos
	CasaDestino     string `gorm:"not null"` // "Torre B, Depto 102" — coincide con Destino.Nombre
	Telefono        string
	AccesoID        uint `gorm:"not null;index"`
	TiempoEsperaMin *int // nil = usar el del AccesoConfig del kiosko
}

func (Residente) TableName() string { return "residentes" }
