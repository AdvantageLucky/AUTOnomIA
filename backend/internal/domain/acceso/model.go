/*
Package acceso
DB Models

Models Acceso y AccesoConfig
Acceso: Este representa la tabla Acceso en la base de datos con la ayuda de gorm
AccesoConfig: Almacena la configuracion parametrizable de un Acceso. Relacion 1:1 con Acceso

Acceso 1:1 AdminID
Acceso 1:1 ConfigAcceso
*/
package acceso

import "gorm.io/gorm"

type Acceso struct {
	gorm.Model
	Nombre      string `gorm:"not null"`
	Ubicacion   string
	ClaveKiosko string `gorm:"not null" json:"-"` // hash bcrypt de la credencial con la que el kiosko inicia sesion (ver internal/domain/auth/)
	AdminID     uint   `gorm:"not null"`
}

type AccesoConfig struct {
	gorm.Model
	AccesoID uint `gorm:"uniqueIndex;not null"`

	// Apariencia
	ColorKiosko  string `gorm:"not null;default:'oscuro'"` // "claro" | "oscuro"
	IdiomaKiosko string `gorm:"not null;default:'es'"`     // "es" | "en"

	// Bitacora para visitantes sin invitacion
	FotoPlacaVisitante  bool `gorm:"not null;default:false"`
	FotoRostroVisitante bool `gorm:"not null;default:true"`
	FotoIneVisitante    bool `gorm:"not null;default:true"`

	// Bitacora para visitantes con invitacion
	FotoPlacaInvitado  bool `gorm:"not null;default:false"`
	FotoRostroInvitado bool `gorm:"not null;default:false"`
	FotoIneInvitado    bool `gorm:"not null;default:false"`

	// Comportamiento de solicitudes
	TiempoEsperaMin   int    `gorm:"not null;default:5"` // minutos antes de auto-rechazar
	HorarioInicio     string `gorm:"not null;default:'00:00'"`
	HorarioFin        string `gorm:"not null;default:'23:59'"`
	MensajeBienvenida string
}

func (AccesoConfig) TableName() string { return "acceso_configs" }
