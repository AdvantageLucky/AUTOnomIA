package visitas

import "gorm.io/gorm"

type TipoDocumento string

const (
	DocumentoINE       TipoDocumento = "INE"
	DocumentoPasaporte TipoDocumento = "PASAPORTE"
	DocumentoLicencia  TipoDocumento = "LICENCIA"
)

type EstadoVisita string

const (
	EstadoPendiente  EstadoVisita = "PENDIENTE"
	EstadoAprobado   EstadoVisita = "APROBADO"
	EstadoRechazado  EstadoVisita = "RECHAZADO"
)

// Visita es un registro de entrada al fraccionamiento: combina identidad del visitante (INE/pasaporte),
// el motivo de su visita, y el estado de aprobación del residente al que viene a ver.
type Visita struct {
	gorm.Model
	Nombre           string        `gorm:"not null"`
	TipoDocumento    TipoDocumento `gorm:"not null"`
	ClaveLector      string        `gorm:"not null"`
	Curp             string        `gorm:"not null"`
	FotoDocumentoURL string        `gorm:"not null"`
	FotoRostroURL    string        `gorm:"not null"`
	FotoPlacaURL     string
	MotivoVisita     string        `gorm:"not null"`
	CasaDestino      string        `gorm:"not null"`
	Placa            string
	Estado           EstadoVisita  `gorm:"not null;default:'PENDIENTE'"`
	AccesoID         uint          `gorm:"not null;index"`
}

func (Visita) TableName() string { return "visitas" }
