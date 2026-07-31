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

type Kiosko struct {
	gorm.Model
	Nombre      string `gorm:"not null"`
	Ubicacion   string
	ClaveKiosko string `gorm:"not null" json:"-"` // hash bcrypt de la credencial con la que el kiosko inicia sesion (ver internal/domain/auth/)
	AdminID     uint   `gorm:"not null"`
}

type KioskoConfig struct {
	gorm.Model
	KioskoID uint `gorm:"uniqueIndex;not null"`

	// Apariencia
	ColorKiosko  string `gorm:"not null;default:'oscuro'"` // "claro" | "oscuro"
	IdiomaKiosko string `gorm:"not null;default:'es'"`     // "es" | "en"

	// Bitacora para visitantes sin invitacion
	// la ine siempre sera requerida en el caso de sin invitacion
	// para asegurar busquedas sobre nombre, curp, etc
	FotoPlacaVisitante  bool `gorm:"not null;default:false"`
	FotoRostroVisitante bool `gorm:"not null;default:true"`

	// Bitacora para visitantes con invitacion
	FotoPlacaInvitado          bool `gorm:"not null;default:false"`
	FotoRostroInvitado         bool `gorm:"not null;default:false"`
	IneObligatorioInvitado bool `gorm:"not null;default:false"`

	// Comportamiento de solicitudes
	TiempoEsperaMin   int    `gorm:"not null;default:5"` // minutos antes de auto-rechazar
	HorarioInicio     string `gorm:"not null;default:'00:00'"`
	HorarioFin        string `gorm:"not null;default:'23:59'"`
	MensajeBienvenida string

	// Configuracion de IA
	AutoPassHabilitado     bool `gorm:"not null;default:true"`
	UmbralConfianzaVisitas int  `gorm:"not null;default:5"`
}

func (Kiosko) TableName() string       { return "kioskos" }
func (KioskoConfig) TableName() string { return "kiosko_configs" }
