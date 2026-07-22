/*
Package visitas
DB Models

Type TipoDocumento, EstadoVisita
TipoDocumento: Tipo string personalizado para documentos permitidos
EstadoVisita: Tipo string personalizado para estado de una visita (solicitud)

Model Visita
Visita: Registro de entrada al fraccionamiento: quien es, a donde va, informacion extra, etc
*/
package visitas

import "gorm.io/gorm"

type (
	TipoDocumento string
	EstadoVisita  string
)

const (
	// TipoDocumento
	DocumentoINE       TipoDocumento = "INE"
	DocumentoPasaporte TipoDocumento = "PASAPORTE"
	DocumentoLicencia  TipoDocumento = "LICENCIA"

	// EstadoVisita
	EstadoPendiente EstadoVisita = "PENDIENTE"
	EstadoAprobado  EstadoVisita = "APROBADO"
	EstadoRechazado EstadoVisita = "RECHAZADO"
	EstadoRevision  EstadoVisita = "REVISION"
)

type Visita struct {
	gorm.Model
	Nombre           string        `gorm:"not null"`
	TipoDocumento    TipoDocumento `gorm:"not null"`
	ClaveLector      string        `gorm:"not null"`
	Curp             string        `gorm:"not null"`
	FotoDocumentoURL string        `gorm:"not null"`
	FotoRostroURL    string        `gorm:"not null"`
	FotoPlacaURL     string
	MotivoVisita     string `gorm:"not null"`
	CasaDestino      string `gorm:"not null"`
	Placa            string
	Estado      EstadoVisita `gorm:"not null;default:'PENDIENTE'"`
	Intervenida bool         `gorm:"not null;default:false"`
	KioskoID    uint         `gorm:"not null;index"`
}

func (Visita) TableName() string { return "visitas" }
