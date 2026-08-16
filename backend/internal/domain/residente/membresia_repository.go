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
