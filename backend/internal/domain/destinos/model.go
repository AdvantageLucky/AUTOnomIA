/*
Package destinos
DB Models

Model Destinos
Destinos: Representa la tabla de lugares posibles a visitar por una Visita Sin Invitacion
*/
package destinos

import "gorm.io/gorm"

// Destino representa un departamento, casa o edificio dentro del fraccionamiento
// Cada destino tiene un titular (el residente registrado) que el sistema de IA
// puede usar para verificar a quien viene a ver un visitante con el sistema STT
type Destino struct {
	gorm.Model
	Nombre   string `gorm:"not null"` // "Torre B, Depto 102"
	Titular  string `gorm:"not null"` // nombre completo del residente
	AccesoID uint   `gorm:"not null;index"`
}

func (Destino) TableName() string { return "destinos" }
