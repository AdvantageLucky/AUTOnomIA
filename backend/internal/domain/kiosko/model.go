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

import (
	"time"

	"gorm.io/gorm"
)

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
	// UltimoPing se actualiza en cada POST /kioskos/:id/ping -- el dashboard
	// admin lo usa para mostrar "en línea" / "desconectado hace Xm" sin
	// depender de que alguien mire el kiosko en persona.
	UltimoPing *time.Time
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
	// A un invitado no se le pregunta el motivo en el kiosko -- quien lo
	// invitó ya lo capturó al crear la invitación. Este toggle solo aplica
	// a quien llega sin invitación (peatonal o vehicular).
	MotivoObligatorioVisitante bool `gorm:"column:motivo_obligatorio_visitante;not null;default:false"`

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
	AutoPassHabilitado bool `gorm:"not null;default:true"`
	// Similitud coseno minima (0-100) para dar por buena una cara en el
	// kiosko. Ver migracion 000058.
	UmbralFacialPct int `gorm:"column:umbral_facial_pct;not null;default:85"`
	// Score de confianza minimo (0-100) para que una entrada se apruebe sola.
	// Sustituye al contador de aprobaciones consecutivas.
	UmbralAutopassPct   int     `gorm:"column:umbral_autopass_pct;not null;default:80"`
	UmbralSimilitudCara float64 `gorm:"not null;default:0.70"` // similitud mínima para reconocimiento facial

	// Nuevos campos de UI configurable
	TiempoExitoSeg int `gorm:"not null;default:5"`

	// Numero del vigilante/admin que muestra el botón "hablar con el
	// administrador" del kiosko -- funciona incluso sin internet en el
	// kiosko porque el visitante marca desde su propio celular (red móvil,
	// no el wifi del kiosko).
	TelefonoContacto string `gorm:"column:telefono_contacto;not null;default:''"`

	// Si el visitante ve el sello "Verificado por IA" y el detalle de
	// vigilante en el kiosko (ver AnalisisIaView). Prendido por default --
	// un admin que no lo quiera lo apaga desde el dashboard.
	MostrarScoreIaKiosko bool `gorm:"column:mostrar_score_ia_kiosko;not null;default:true"`

	// Qué evidencia cuenta para ligar una visita con su historial (identidad
	// para recurrencia/anomalías) y para los factores de comparación entre
	// visitas -- no es lo mismo que FotoRostro*/FotoIne*/FotoPlaca* (esas
	// deciden si se PIDE capturarla). Los 3 prendidos por default; el admin
	// apaga uno cuando el dato de prueba no es único por persona durante una
	// demo (mismo vehículo, mismo rostro o CURP de prueba reutilizado entre
	// varios actores) y el análisis lo leería como "el mismo visitante
	// recurrente" sin serlo.
	UsarPlacaEnScoreIA     bool `gorm:"column:usar_placa_en_score_ia;not null;default:true"`
	UsarDocumentoEnScoreIA bool `gorm:"column:usar_documento_en_score_ia;not null;default:true"`
	UsarRostroEnScoreIA    bool `gorm:"column:usar_rostro_en_score_ia;not null;default:true"`
}

func (Kiosko) TableName() string       { return "kioskos" }
func (KioskoConfig) TableName() string { return "kiosko_configs" }
