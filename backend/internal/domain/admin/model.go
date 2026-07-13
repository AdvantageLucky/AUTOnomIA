/*
Package admin

Paquete de modelo Admin. Este representa la tabla Admin en la base de datos con la ayuda de gorm
Un Admin es el administrador de uno o varios Accesos de un condominio, y es la entidad raiz
contra la que se autentica el login (ver internal/domain/auth/)
*/
package admin

import "gorm.io/gorm"

type Admin struct {
	gorm.Model
	Nombre          string
	ApellidoPaterno string
	ApellidoMaterno string
	Correo          string `gorm:"not null;uniqueIndex"`          // identificador unico de login
	Password        string `gorm:"not null"             json:"-"` // hash bcrypt, nunca se expone en JSON
}
