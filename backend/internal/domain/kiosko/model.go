/*
Package kiosko
DB Models

Models Kiosko y KioskoConfig
Kiosko: Representa la tabla kioskos en la base de datos con la ayuda de gorm
KioskoConfig: Almacena la configuracion parametrizable de un Kiosko. Relacion 1:1 con Kiosko

Kiosko 1:1 AdminID
Kiosko 1:1 KioskoConfig
*/
package kiosko

import "gorm.io/gorm"

type TipoKiosko string

const (
	KioskoVehicular TipoKiosko = "VEHICULAR"
	KioskoPeatonal  TipoKiosko = "PEATONAL"
)

type Kiosko struct {
	gorm.Model
	TenantID    uint       `gorm:"column:tenant_id;not null;index"`
	Nombre      string     `gorm:"not null"`
	Tipo        TipoKiosko `gorm:"not null"`
	Ubicacion   string
	ClaveKiosko string `gorm:"not null" json:"-"` // hash bcrypt de la credencial con la que el kiosko inicia sesion (ver internal/domain/auth/)
	AdminID     uint   `gorm:"not null"`
}

type KioskoConfig struct {
	gorm.Model
	KioskoID uint `gorm:"uniqueIndex;not null"`
	TenantID uint `gorm:"column:tenant_id;not null;index"`

	// Apariencia
	ColorKiosko  string `gorm:"not null;default:'oscuro'"` // "claro" | "oscuro"
	IdiomaKiosko string `gorm:"not null;default:'es'"`     // "es" | "en"

	// Bitacora para visitantes sin invitacion
	FotoPlacaVisitante  bool   `gorm:"not null;default:false"`
	FotoRostroVisitante bool   `gorm:"not null;default:true"`
	FotoIneVisitante    bool   `gorm:"not null;default:false"`
	PasosSinInvitacion  string `gorm:"not null;default:'[\"ROSTRO\",\"DESTINO\"]'"`

	// Bitacora para visitantes con invitacion
	FotoPlacaInvitado      bool `gorm:"not null;default:false"`
	FotoRostroInvitado     bool `gorm:"not null;default:false"`
	IneObligatorioInvitado bool `gorm:"not null;default:false"`

	// Comportamiento de solicitudes
	TiempoEsperaSeg   int    `gorm:"not null;default:90"` // segundos antes de liberar el kiosko o escalar a revisión si nadie responde
	HorarioInicio     string `gorm:"not null;default:'00:00'"`
	HorarioFin        string `gorm:"not null;default:'23:59'"`
	MensajeBienvenida string

	// Configuracion de IA
	AutoPassHabilitado     bool    `gorm:"not null;default:true"`
	UmbralConfianzaVisitas int     `gorm:"not null;default:5"`
	UmbralSimilitudCara    float64 `gorm:"not null;default:0.70"` // similitud mínima para reconocimiento facial

	// Nuevos campos de UI configurable
	ScreensaverHabilitado  bool   `gorm:"not null;default:true"`
	ModoCapturaNombre      string `gorm:"not null;default:'TECLADO'"`
	MostrarNombreInvitado  bool   `gorm:"not null;default:false"`
	TiempoExitoSeg         int    `gorm:"not null;default:5"`
	LectorFisicoHabilitado bool   `gorm:"not null;default:false"`
}

func (Kiosko) TableName() string       { return "kioskos" }
func (KioskoConfig) TableName() string { return "kiosko_configs" }
