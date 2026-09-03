package visitas

import (
	"strings"
	"time"

	"gorm.io/gorm"
)

// HistorialReset marca que la confianza acumulada con una identidad
// (PersonaID) se "olvida" a partir de cierto punto, para el cálculo de
// score de confianza (recurrencia, racha limpia, cambio de modalidad).
//
// CasaDestino vacío es un reset GLOBAL: solo lo puede pedir un admin (ve a
// todos los residentes/casas), y aplica sin importar a qué destino llegue
// esta identidad después. CasaDestino no vacío es un reset de UN
// residente: solo aplica cuando la visita analizada tiene esa misma
// CasaDestino -- un residente puede "olvidar" la confianza que un
// visitante se ganó con ÉL, sin borrar la que se ganó (o no) con el resto
// del centro habitacional.
type HistorialReset struct {
	gorm.Model
	TenantID          uint      `gorm:"column:tenant_id;not null;index"`
	PersonaID         uint      `gorm:"column:persona_id;not null;index"`
	CasaDestino       string    `gorm:"column:casa_destino;not null;default:''"`
	ResetAt           time.Time `gorm:"column:reset_at;not null"`
	ResetPorPersonaID *uint     `gorm:"column:reset_por_persona_id"`
	ResetPorAdminID   *uint     `gorm:"column:reset_por_admin_id"`
}

func (HistorialReset) TableName() string { return "historial_resets" }

// CrearReset registra un nuevo reset -- no borra ni modifica ninguna
// Visita existente, solo agrega un punto de corte que el análisis futuro
// respeta (ver aplicarResetHistorial). Exactamente uno de
// resetPorPersonaID/resetPorAdminID debe venir no-nil, según quién lo pide.
func (r *Repository) CrearReset(tenantID, personaID uint, casaDestino string, resetPorPersonaID, resetPorAdminID *uint) error {
	return r.db.Create(&HistorialReset{
		TenantID: tenantID, PersonaID: personaID, CasaDestino: strings.TrimSpace(casaDestino),
		ResetAt: time.Now(), ResetPorPersonaID: resetPorPersonaID, ResetPorAdminID: resetPorAdminID,
	}).Error
}

// aplicarResetHistorial descarta del historial las visitas que un reset
// aplicable ya dio por olvidadas. Un reset global (CasaDestino == "")
// descarta CUALQUIER visita anterior a él, sin importar a qué casa haya
// sido -- lo pide un admin, ve a toda la identidad. Un reset de residente
// (CasaDestino == la casa del residente) solo descarta las visitas HACIA
// ESA MISMA CASA anteriores a él -- "SOLO LOS MIOS": la confianza que esta
// identidad se ganó en cualquier otro destino del tenant no se toca.
func (r *Repository) aplicarResetHistorial(tenantID, personaID uint, casaDestino string, historial []Visita) ([]Visita, error) {
	var resets []HistorialReset
	if err := r.db.Where("tenant_id = ? AND persona_id = ?", tenantID, personaID).
		Find(&resets).Error; err != nil {
		return nil, err
	}
	if len(resets) == 0 {
		return historial, nil
	}

	var corteGlobal, corteCasa time.Time
	for _, reset := range resets {
		if reset.CasaDestino == "" {
			if reset.ResetAt.After(corteGlobal) {
				corteGlobal = reset.ResetAt
			}
		} else if strings.EqualFold(reset.CasaDestino, casaDestino) && reset.ResetAt.After(corteCasa) {
			corteCasa = reset.ResetAt
		}
	}
	if corteGlobal.IsZero() && corteCasa.IsZero() {
		return historial, nil
	}

	filtrado := historial[:0]
	for _, vh := range historial {
		if !corteGlobal.IsZero() && !vh.CreatedAt.After(corteGlobal) {
			continue
		}
		if !corteCasa.IsZero() && strings.EqualFold(vh.CasaDestino, casaDestino) && !vh.CreatedAt.After(corteCasa) {
			continue
		}
		filtrado = append(filtrado, vh)
	}
	return filtrado, nil
}
