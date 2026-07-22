/*
Package admin
DB Models

Model Admin
Admin: Representa admins en la base de datos con ayuda de gorm
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
	Rol             string `gorm:"not null;default:'admin'"`
}
