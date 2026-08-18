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

// MembresiaPendienteConPersona es una fila de FindPendientesPorTenant —
// junta la Membresia con nombre/teléfono de su Persona (query cruda contra
// la tabla personas, para no importar el paquete persona y crear un ciclo:
// persona ya importa residente). Mismo patrón que BuscarCentroPorCodigo.
type MembresiaPendienteConPersona struct {
	ID          uint   `json:"id"`
	PersonaID   uint   `json:"persona_id" gorm:"column:persona_id"`
	Nombre      string `json:"nombre"`
	Telefono    string `json:"telefono"`
	CasaDestino string `json:"casa_destino" gorm:"column:casa_destino"`
	Rol         string `json:"rol"`
	Status      string `json:"status"`
}

// FindPendientesPorTenant devuelve las membresías pendientes de aprobación
// de un tenant, con el nombre y teléfono de la Persona que las solicitó —
// sin eso, el admin no tiene forma de saber a quién está aprobando.
func (r *MembresiaRepository) FindPendientesPorTenant(tenantID uint) ([]MembresiaPendienteConPersona, error) {
	var list []MembresiaPendienteConPersona
	err := r.db.Table("membresias").
		Select("membresias.id, membresias.persona_id, "+
			"trim(personas.nombre || ' ' || personas.apellido_paterno) as nombre, "+
			"personas.telefono, membresias.casa_destino, membresias.rol, membresias.status").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Where("membresias.tenant_id = ? AND membresias.status = ? AND membresias.deleted_at IS NULL", tenantID, ResidenteStatusPendiente).
		Order("membresias.created_at DESC").
		Scan(&list).Error
	return list, err
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

// FindByPersonaID lista todas las membresías de una Persona, en cualquier
// tenant y cualquier status — usado por la app para resolver su propia
// sesión (¿ya pertenezco a algún centro? ¿en qué estado?).
func (r *MembresiaRepository) FindByPersonaID(personaID uint) ([]Membresia, error) {
	var list []Membresia
	if err := r.db.
		Where("persona_id = ?", personaID).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}
