// backend/internal/domain/residente/membresia_model.go
package residente

import "gorm.io/gorm"

const (
	// Reusadas por Membresia.Status (y antes por Residente.Status, ya
	// eliminado) — el ciclo de aprobación activo/pendiente/rechazado es el
	// mismo para ambos.
	ResidenteStatusActivo    = "activo"
	ResidenteStatusPendiente = "pendiente"
	ResidenteStatusRechazado = "rechazado"

	// Membresia.Rol -- RolInvitadoFrecuente reusa exactamente el mismo
	// mecanismo de reconocimiento facial que un residente (cualquier
	// Membresia activa con embedding entra por match de rostro, ver
	// persona.Repository.FindActivasPorTenant) en vez de un sistema de
	// reconocimiento paralelo. Lo que cambia es semántico: no es
	// "residente" de la casa, es un invitado al que un residente le dio
	// acceso recurrente y puede revocar cuando quiera.
	RolResidente         = "residente"
	RolInvitadoFrecuente = "invitado_frecuente"
)

// Membresia es la relación de una Persona (internal/domain/persona) con un
// tenant específico — reemplaza lo que hoy vive dentro de Residente (nombre,
// teléfono y embedding se mueven a Persona; casa_destino, pin y rol se
// quedan aquí, porque son propios de cada centro habitacional). Ver spec
// 2026-08-16-persona-identidad-kigo-design.md §2.
//
// Status reusa las constantes ResidenteStatus* de arriba (activo |
// pendiente | rechazado) — el ciclo de aprobación es el mismo.
type Membresia struct {
	gorm.Model
	PersonaID   uint   `gorm:"column:persona_id;not null;index"`
	TenantID    uint   `gorm:"column:tenant_id;not null;index"`
	CasaDestino string `gorm:"not null"`
	// DestinoID liga con destinos.id cuando CasaDestino pudo resolverse a un
	// Destino real -- null en membresías viejas sin match.
	DestinoID *uint `gorm:"column:destino_id;index"`
	// Pin guarda el hash bcrypt (lo que compara el kiosko, incluso
	// offline); PinCodigo guarda los 5 dígitos en claro que genera el
	// backend al crear la membresía, porque la app se los tiene que poder
	// mostrar al residente en "Mi QR". El PIN ya no lo elige la persona y
	// no cambia una vez asignado.
	Pin                         string `gorm:"not null"`
	PinCodigo                   string `gorm:"column:pin_codigo;not null;default:''"`
	Status                      string `gorm:"not null;default:'activo'"`
	PermiteReconocimientoFacial bool   `gorm:"not null;default:false"`
	KioskoID                    *uint
	TiempoEsperaMin             *int
	// Rol distingue un residente real de un invitado frecuente -- ver
	// RolInvitadoFrecuente arriba. Default 'residente' para no romper filas
	// existentes.
	Rol string `gorm:"not null;default:'residente'"`
}

func (Membresia) TableName() string { return "membresias" }
