package invitaciones

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

var ErrInvitacionNoValida = errors.New("invitacion no valida, expirada o agotada")

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(inv *Invitacion) error {
	return r.db.Create(inv).Error
}

// FindByID busca una invitación por su ID sin más filtro -- lo usa
// EliminarInvitacionRecibida para saber si la invitación que se está
// ocultando además enroló a quien la recibió, antes de decidir si también
// hay que revocar esa membresía.
func (r *Repository) FindByID(id uint) (*Invitacion, error) {
	var inv Invitacion
	if err := r.db.First(&inv, id).Error; err != nil {
		return nil, err
	}
	return &inv, nil
}

// FindByToken busca una invitacion activa por su token
// Devuelve ErrInvitacionNoValida si está revocada, expirada o agotada.
func (r *Repository) FindByToken(token string) (*Invitacion, error) {
	var inv Invitacion
	if err := r.db.Where("token = ?", token).First(&inv).Error; err != nil {
		return nil, ErrInvitacionNoValida
	}
	if inv.ExpiresAt != nil && inv.ExpiresAt.Before(time.Now()) {
		return nil, ErrInvitacionNoValida
	}
	if inv.MaxUsos != nil && inv.ConteoUsos >= *inv.MaxUsos {
		return nil, ErrInvitacionNoValida
	}
	return &inv, nil
}

// FindByPersonaCreadora lista las invitaciones activas creadas por una Persona.
func (r *Repository) FindByPersonaCreadora(personaID uint) ([]Invitacion, error) {
	var list []Invitacion
	err := r.db.Where("persona_creadora_id = ?", personaID).
		Order("created_at DESC").
		Find(&list).Error
	return list, err
}

// ContactoFrecuente es una persona a la que ya se invitó antes -- ver
// FindContactosFrecuentes.
type ContactoFrecuente struct {
	PersonaID uint   `json:"persona_id"`
	Nombre    string `json:"nombre"`
	Telefono  string `json:"telefono"`
	Titular   string `json:"titular"`
	DestinoID uint   `json:"destino_id"`
}

// FindContactosFrecuentes lista, una vez por persona, a quien ya se invitó
// antes desde esta cuenta -- así "invitar de nuevo" no obliga a volver a
// teclear teléfono y nombre cada vez. Se deriva del historial de
// invitaciones (sin tabla nueva): un DISTINCT ON por persona_invitada_id
// con los datos de su invitación más reciente, ordenado por esa misma
// recencia.
func (r *Repository) FindContactosFrecuentes(personaCreadoraID uint, limite int) ([]ContactoFrecuente, error) {
	var list []ContactoFrecuente
	err := r.db.Raw(`
		SELECT * FROM (
			SELECT DISTINCT ON (i.persona_invitada_id)
				i.persona_invitada_id AS persona_id, p.nombre, p.telefono,
				i.titular, i.destino_id, i.created_at
			FROM invitaciones i
			JOIN personas p ON p.id = i.persona_invitada_id
			WHERE i.persona_creadora_id = ? AND i.deleted_at IS NULL
			ORDER BY i.persona_invitada_id, i.created_at DESC
		) recientes
		ORDER BY recientes.created_at DESC
		LIMIT ?
	`, personaCreadoraID, limite).Scan(&list).Error
	return list, err
}

// RevocarByIDAndPersonaCreadora hace soft-delete comprobando que la
// invitación pertenece a la Persona que la creó.
func (r *Repository) RevocarByIDAndPersonaCreadora(id, personaID uint) error {
	result := r.db.Where("id = ? AND persona_creadora_id = ?", id, personaID).Delete(&Invitacion{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// RevocarByIDAndPersonaInvitada hace soft-delete comprobando que la
// invitación fue dirigida a esta Persona -- la usa EliminarInvitacionRecibida:
// "eliminar" una invitación recibida no debe dejar su QR/token todavía
// válido en el kiosko, así que revoca la fila entera (igual que
// RevocarByIDAndPersonaCreadora), no solo la oculta de la lista.
func (r *Repository) RevocarByIDAndPersonaInvitada(id, personaID uint) error {
	result := r.db.Where("id = ? AND persona_invitada_id = ?", id, personaID).Delete(&Invitacion{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindByPersonaInvitada lista las invitaciones activas (no revocadas, no
// expiradas, no agotadas) dirigidas a una Persona — usado por kigo-app para
// mostrar "invitaciones recibidas" sin importar el tenant.
func (r *Repository) FindByPersonaInvitada(personaID uint) ([]Invitacion, error) {
	var list []Invitacion
	err := r.db.
		Where("persona_invitada_id = ? AND conteo_usos = 0 AND (expires_at IS NULL OR expires_at > ?) AND oculta_para_invitado = false", personaID, time.Now()).
		Order("created_at DESC").
		Find(&list).Error
	return list, err
}

// OcultarParaInvitado quita una invitación de la lista de "recibidas" de
// quien la recibió, sin tocar la fila que ve quien la creó -- comprueba que
// personaID sea justo el destinatario, para que nadie pueda ocultarle a
// otro una invitación que no es suya.
func (r *Repository) OcultarParaInvitado(id, personaID uint) error {
	result := r.db.Model(&Invitacion{}).
		Where("id = ? AND persona_invitada_id = ?", id, personaID).
		Update("oculta_para_invitado", true)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindActivaByPersonaInvitadaAndTenant busca si una Persona tiene una
// invitación activa (no expirada, no agotada) en un tenant — usado por el
// kiosko al resolver un QR (ver persona.ResolverEstadoQR).
func (r *Repository) FindActivaByPersonaInvitadaAndTenant(personaID, tenantID uint) (*Invitacion, error) {
	var inv Invitacion
	if err := r.db.
		Where("persona_invitada_id = ? AND tenant_id = ?", personaID, tenantID).
		Order("created_at DESC").
		First(&inv).Error; err != nil {
		return nil, err
	}
	if inv.ExpiresAt != nil && inv.ExpiresAt.Before(time.Now()) {
		return nil, gorm.ErrRecordNotFound
	}
	if inv.MaxUsos != nil && inv.ConteoUsos >= *inv.MaxUsos {
		return nil, gorm.ErrRecordNotFound
	}
	return &inv, nil
}

// IncrementarUso suma uno al ConteoUsos y si el resultado alcanza MaxUsos entonces revoca
func (r *Repository) IncrementarUso(id uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {
		var inv Invitacion
		if err := tx.First(&inv, id).Error; err != nil {
			return err
		}
		inv.ConteoUsos++
		if err := tx.Save(&inv).Error; err != nil {
			return err
		}
		if inv.MaxUsos != nil && inv.ConteoUsos >= *inv.MaxUsos {
			return tx.Delete(&inv).Error
		}
		return nil
	})
}

// FindActivasNoExpiradasByTenant lista las invitaciones utilizables de un
// tenant — para el snapshot offline del kiosko: solo las que un kiosko sin
// red podria consumir validamente si el usuario las trae.
func (r *Repository) FindActivasNoExpiradasByTenant(tenantID uint) ([]Invitacion, error) {
	var lista []Invitacion
	err := r.db.
		Where("tenant_id = ?", tenantID).
		Where("expires_at IS NULL OR expires_at > ?", time.Now()).
		Where("max_usos IS NULL OR conteo_usos < max_usos").
		Find(&lista).Error
	return lista, err
}
