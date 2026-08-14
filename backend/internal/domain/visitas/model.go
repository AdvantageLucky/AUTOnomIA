package visitas

import "gorm.io/gorm"

type (
	TipoVisitante string
	TipoDocumento string
	EstadoVisita  string
)

const (
	// TipoVisitante
	TipoConInvitacion TipoVisitante = "INVITADO"
	TipoSinInvitacion TipoVisitante = "VISITANTE"
	TipoResidente     TipoVisitante = "RESIDENTE"

	// TipoDocumento
	DocumentoINE       TipoDocumento = "INE"
	DocumentoPasaporte TipoDocumento = "PASAPORTE"
	DocumentoLicencia  TipoDocumento = "LICENCIA"
	DocumentoQR        TipoDocumento = "QR"
	DocumentoPIN       TipoDocumento = "PIN"
	DocumentoRostro    TipoDocumento = "ROSTRO"
	// DocumentoPlaca: en un acceso vehicular la matricula es lo que identifica a
	// la visita, sin documento de identidad de por medio (ver ADR-0024)
	DocumentoPlaca TipoDocumento = "PLACA"

	// EstadoVisita
	EstadoPendiente EstadoVisita = "PENDIENTE"
	EstadoAprobado  EstadoVisita = "APROBADO"
	EstadoRechazado EstadoVisita = "RECHAZADO"
	EstadoRevision  EstadoVisita = "REVISION"
)

type Visita struct {
	gorm.Model
	TenantID        uint   `gorm:"column:tenant_id;not null;index"`
	Titular          string        `gorm:"not null"`
	TipoVisitante    TipoVisitante `gorm:"not null;default:'VISITANTE'"`
	TipoDocumento    TipoDocumento `gorm:"not null;default:''"`
	Curp             string        `gorm:"not null"`
	FotoDocumentoURL string        `gorm:"not null"`
	FotoRostroURL    string        `gorm:"not null"`
	FotoPlacaURL     string
	CasaDestino      string `gorm:"not null"`
	Placa            string
	Estado           EstadoVisita `gorm:"not null;default:'PENDIENTE'"`
	Intervenida      bool         `gorm:"not null;default:false"`
	KioskoID         uint         `gorm:"not null;index"`
}

func (Visita) TableName() string { return "visitas" }
