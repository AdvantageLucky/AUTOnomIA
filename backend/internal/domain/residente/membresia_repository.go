// backend/internal/domain/residente/membresia_repository.go
package residente

import "gorm.io/gorm"

type MembresiaRepository struct {
	db *gorm.DB
}

func NewMembresiaRepository(db *gorm.DB) *MembresiaRepository {
	return &MembresiaRepository{db: db}
}

func (r *MembresiaRepository) Create(m *Membresia) error {
	return r.db.Create(m).Error
}

// Update guarda los cambios de una Membresia ya existente — usado para
// reintentar el ingreso a un centro tras un rechazo previo (ver
// Handler.UnirseCentro).
func (r *MembresiaRepository) Update(m *Membresia) error {
	return r.db.Save(m).Error
}

// FindByPersonaAndTenant busca la membresía de una Persona en un tenant
// específico — no usa el scope ByTenant porque el tenant es explícito en la
// firma, no viene del contexto (llamadas fuera de un request HTTP, como el
// backfill, no tienen contexto de petición).
func (r *MembresiaRepository) FindByPersonaAndTenant(personaID, tenantID uint) (*Membresia, error) {
	var m Membresia
	if err := r.db.
		Where("persona_id = ? AND tenant_id = ?", personaID, tenantID).
		First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *MembresiaRepository) FindByCasaDestinoYTenant(tenantID uint, casaDestino string) ([]Membresia, error) {
	var list []Membresia
	if err := r.db.
		Where("tenant_id = ? AND casa_destino = ?", tenantID, casaDestino).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindPendientesPorTenant devuelve las membresías pendientes de aprobación de un tenant.
func (r *MembresiaRepository) FindPendientesPorTenant(tenantID uint) ([]Membresia, error) {
	var list []Membresia
	if err := r.db.
		Where("tenant_id = ? AND status = ?", tenantID, ResidenteStatusPendiente).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindByTenantAndID busca una membresía por ID, comprobando que pertenece al tenant.
func (r *MembresiaRepository) FindByTenantAndID(tenantID, id uint) (*Membresia, error) {
	var m Membresia
	if err := r.db.
		Where("tenant_id = ? AND id = ?", tenantID, id).
		First(&m).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

// UpdateStatus cambia el status de una membresía.
func (r *MembresiaRepository) UpdateStatus(id uint, status string) error {
	return r.db.Model(&Membresia{}).Where("id = ?", id).Update("status", status).Error
}

// UpdatePermiteReconocimientoFacial activa el consentimiento de reconocimiento
// facial de una membresía — se llama cuando el kiosko captura un embedding
// nuevo para una Persona que ya es miembro de este tenant.
func (r *MembresiaRepository) UpdatePermiteReconocimientoFacial(id uint, permite bool) error {
	return r.db.Model(&Membresia{}).Where("id = ?", id).
		Update("permite_reconocimiento_facial", permite).Error
}
