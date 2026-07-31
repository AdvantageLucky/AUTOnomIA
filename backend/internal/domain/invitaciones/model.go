/*
Package invitaciones

# DB Models

TipoInvitacion: PERSONAL (un invitado con nombre) | GRUPAL (grupo con identificador)

Model Invitacion
Token opaco generado por el servidor (hex 32 bytes) y el residente nunca elige el token
El soft-delete de gorm.Model se usa para revocar (DeletedAt != nil → revocada)
- MaxUsos nil = sin limite de usos
- ExpiresAt nil = sin expiracion
- ConteoUsos se incrementa por IncrementarUso y al alcanzar MaxUsos se auto-revoca
*/
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

// Invitacion representa un token de acceso que un residente emite para uno o varios visitantes
// El token es opaco (hex de 32 bytes) generado por el servidor
// El soft-delete de gorm.Model se usa para revocar (DeletedAt != nil → revocada)
type Invitacion struct {
	gorm.Model
	Token       string         `gorm:"not null;uniqueIndex"`
	Tipo        TipoInvitacion `gorm:"not null;default:'PERSONAL'"`
	Titular     string         `gorm:"not null"` // nombre del invitado (PERSONAL) o identificador del grupo (GRUPAL)
	ResidenteID uint           `gorm:"not null;index"`
	DestinoID   uint           `gorm:"not null"`
	ConteoUsos  int            `gorm:"not null;default:0"`
	MaxUsos     *int           // nil = sin limite
	ExpiresAt   *time.Time     // nil = sin expiracion
}

func (Invitacion) TableName() string { return "invitaciones" }
