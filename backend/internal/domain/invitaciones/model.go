package invitaciones

import (
	"time"

	"gorm.io/gorm"
)

type TipoInvitacion string

const (
	InvitacionPersonal TipoInvitacion = "PERSONAL"
	InvitacionGrupal   TipoInvitacion = "GRUPAL"
)

type Invitacion struct {
	gorm.Model
	TenantID                    uint           `gorm:"column:tenant_id;not null;index"`
	Token                       string         `gorm:"not null;uniqueIndex"`
	Tipo                        TipoInvitacion `gorm:"not null;default:'PERSONAL'"`
	Titular                     string         `gorm:"not null"` // nombre del invitado (PERSONAL) o identificador del grupo (GRUPAL)
	ResidenteID                 uint           `gorm:"not null;index"`
	DestinoID                   uint           `gorm:"not null"`
	ConteoUsos                  int            `gorm:"not null;default:0"`
	MaxUsos                     *int           // nil = sin limite
	ExpiresAt                   *time.Time     // nil = sin expiracion
	PersonaInvitadaID           *uint          `gorm:"column:persona_invitada_id;index"`
	PersonaCreadoraID           *uint          `gorm:"column:persona_creadora_id;index"`
	PermiteReconocimientoFacial bool           `gorm:"column:permite_reconocimiento_facial;not null;default:false"`
	// Motivo lo captura quien invita, no el kiosko -- para un invitado no
	// tiene sentido preguntarle "a qué viene" si quien lo invitó ya lo sabe.
	// Viaja a la Visita al consumir la invitación (ver UsarInvitacion).
	Motivo string `gorm:"not null;default:''"`
}

func (Invitacion) TableName() string { return "invitaciones" }
