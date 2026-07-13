/*
Package visitantes

Paquete de modelo de Visitante. Este representa la tabla Visitante en la base de datos con la ayuda de gorm
*/
package visitantes

import (
	"gorm.io/gorm"
)

type TipoDocumento string

const (
	DocumentoINE       TipoDocumento = "INE"
	DocumentoPasaporte TipoDocumento = "PASAPORTE"
	DocumentoLicencia  TipoDocumento = "LICENCIA"
)

type Visitante struct {
	gorm.Model
	Nombre           string        `gorm:"not null"`
	TipoDocumento    TipoDocumento `gorm:"not null"`
	ClaveLector      string        `gorm:"not null"`
	Curp             string        `gorm:"not null"`
	FotoDocumentoURL string        `gorm:"not null"`       // foto del documento (INE/pasaporte/licencia)
	FotoRostroURL    string        `gorm:"not null"`       // foto de la cara de la persona
	AccesoID         uint          `gorm:"not null;index"` // ForeignKey que conecta Visitante con el Acceso por el que entro
}
