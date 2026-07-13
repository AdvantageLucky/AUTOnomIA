/*
Package acceso

Paquete de modelo Acceso. Este representa la tabla Acceso en la base de datos con la ayuda de gorm
*/
package acceso

import (
	"gorm.io/gorm"
)

type Acceso struct {
	gorm.Model
	Nombre      string `gorm:"not null"` // "Entrada A", "Puerto 3"
	Ubicacion   string
	ClaveKiosko string `gorm:"not null" json:"-"` // hash bcrypt de la credencial con la que el kiosko inicia sesion (ver internal/domain/auth/)
	AdminID     uint   `gorm:"not null"`          // ForeignKey 1-1
}
