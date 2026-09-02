package visitas

import (
	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/residente"
)

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
	AutorizadorPropio    = "PROPIO"  // residente entrando con su propio PIN/rostro -- se autoriza a sí mismo
)

type Visita struct {
	gorm.Model
	TenantID         uint          `gorm:"column:tenant_id;not null;index"`
	Titular          string        `gorm:"not null"`
	TipoVisitante    TipoVisitante `gorm:"not null;default:'VISITANTE'"`
	TipoDocumento    TipoDocumento `gorm:"not null;default:''"`
	Curp             string        `gorm:"not null"`
	FotoDocumentoURL string        `gorm:"not null"`
	// Nitidez de FotoDocumentoURL: varianza cruda del Laplaciano calculada
	// en el kiosko (mismo umbral que ya decide si aceptar la foto, ver
	// EvidenciaCalidadServicio) y la etiqueta derivada de esa varianza.
	// El número crudo se guarda para poder recalibrar los cortes de
	// CalidadIne despues sin volver a tomar fotos.
	NitidezIneScore float64 `gorm:"column:nitidez_ine_score;not null;default:0"`
	CalidadIne      string  `gorm:"column:calidad_ine;not null;default:''"`
	FotoRostroURL   string  `gorm:"not null"`
	FotoPlacaURL    string
	// Motivo: por qué viene el visitante (reparto, visita, servicio...).
	// Campo del núcleo obligatorio del reto FEPRO ("Nombre, motivo,
	// anfitrión/destino") -- no bloquea el registro si viene vacío (un
	// acceso vehicular recurrente puede no pedirlo), pero se captura
	// cuando el kiosko lo pide.
	Motivo      string `gorm:"not null;default:''"`
	CasaDestino string `gorm:"not null"`
	// DestinoID liga con destinos.id cuando CasaDestino pudo resolverse a un
	// Destino real (backfill por texto + resuelto en cada punto de escritura
	// nuevo) -- null en registros viejos sin match, la UI cae al texto.
	DestinoID           *uint `gorm:"column:destino_id;index"`
	Placa               string
	Estado              EstadoVisita `gorm:"not null;default:'PENDIENTE'"`
	Intervenida         bool         `gorm:"not null;default:false"`
	KioskoID            uint         `gorm:"not null;index"`
	ClientID            *string      `gorm:"column:client_id;uniqueIndex"`
	AutorizadoPorTipo   string       `gorm:"column:autorizado_por_tipo"`
	AutorizadoPorNombre string       `gorm:"column:autorizado_por_nombre"`
	// Correo y rol del Admin (rol admin o vigilante) que resolvió -- vacíos
	// cuando el autorizador no es un ADMIN (RESIDENTE, AGENTE, SISTEMA).
	AutorizadoPorCorreo string `gorm:"column:autorizado_por_correo"`
	AutorizadoPorRol    string `gorm:"column:autorizado_por_rol"`
	// Quien resolvio, cuando fue una Persona desde la app. El tipo dice el rol
	// ("RESIDENTE"), pero no cual de los residentes de la casa: eso hace falta
	// para que el historial de cada quien liste solo lo suyo.
	AutorizadoPorPersonaID *uint  `gorm:"column:autorizado_por_persona_id;index"`
	ResumenIA              string `gorm:"column:resumen_ia"`
	ScoreIA                []byte `gorm:"column:score_ia;type:jsonb"`
	PersonaID              *uint  `gorm:"column:persona_id;index"`
	// EmbeddingRostro es la huella facial capturada en esta entrada. Sirve
	// como identificador cuando no hay CURP ni placa: en un flujo de solo
	// rostro + destino es lo unico que liga una visita con las anteriores de
	// la misma persona (ver HistorialDeVisitante). Es un vector, no la foto.
	EmbeddingRostro residente.FloatArray `gorm:"column:embedding_rostro;type:float[]"`
}

func (Visita) TableName() string { return "visitas" }
