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

	// AutorizadoPorTipo — quién resolvió el estado de la visita, para la
	// bitácora (PRD: "quién autorizó"). Vacío mientras sigue PENDIENTE.
	AutorizadorAdmin     = "ADMIN"
	AutorizadorResidente = "RESIDENTE"
	AutorizadorAgente    = "AGENTE"  // auto-pass o auto-revisión del análisis de patrones
	AutorizadorSistema   = "SISTEMA" // escaló por vencer el tiempo de espera, sin que nadie respondiera
)

type Visita struct {
	gorm.Model
	TenantID            uint          `gorm:"column:tenant_id;not null;index"`
	Titular             string        `gorm:"not null"`
	TipoVisitante       TipoVisitante `gorm:"not null;default:'VISITANTE'"`
	TipoDocumento       TipoDocumento `gorm:"not null;default:''"`
	Curp                string        `gorm:"not null"`
	FotoDocumentoURL    string        `gorm:"not null"`
	FotoRostroURL       string        `gorm:"not null"`
	FotoPlacaURL        string
	CasaDestino         string `gorm:"not null"`
	Placa               string
	Estado              EstadoVisita `gorm:"not null;default:'PENDIENTE'"`
	Intervenida         bool         `gorm:"not null;default:false"`
	KioskoID            uint         `gorm:"not null;index"`
	AutorizadoPorTipo   string       `gorm:"column:autorizado_por_tipo"`
	AutorizadoPorNombre string       `gorm:"column:autorizado_por_nombre"`
}

func (Visita) TableName() string { return "visitas" }
