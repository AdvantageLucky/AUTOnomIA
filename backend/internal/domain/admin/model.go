/*
Package admin
DB Models

Model Admin
Admin: Representa admins en la base de datos con ayuda de gorm
*/
package admin

import "gorm.io/gorm"

type Admin struct {
	gorm.Model      `json:"-"`
	ID              uint   `gorm:"primarykey"                      json:"id"`
	TenantID        uint   `gorm:"column:tenant_id;not null;index" json:"tenant_id"` // enlace a centros habitacionales
	Nombre          string `json:"nombre"`
	ApellidoPaterno string `json:"apellido_paterno"`
	ApellidoMaterno string `json:"apellido_materno"`
	Correo          string `gorm:"not null;uniqueIndex"            json:"correo"` // identificador unico de login
	Password        string `gorm:"not null"                        json:"-"`      // hash bcrypt, nunca se expone en JSON
	Rol             string `gorm:"not null;default:'admin'"        json:"rol"`
}
