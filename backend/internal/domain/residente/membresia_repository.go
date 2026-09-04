// backend/internal/domain/residente/membresia_repository.go
package residente

import (
	"time"

	"gorm.io/gorm"
)

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
		Where("tenant_id = ? AND UPPER(casa_destino) = UPPER(?)", tenantID, casaDestino).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// InvitadoFrecuenteFila es una fila de FindInvitadosFrecuentesPorCasa —
// deliberadamente angosta, igual que CompaneroCasa: solo lo que el
// residente que patrocina necesita ver.
type InvitadoFrecuenteFila struct {
	ID       uint   `json:"id"`
	Nombre   string `json:"nombre"`
	Telefono string `json:"telefono"`
	// PersonaID (a diferencia de ID, que es el de la Membresia) es lo que
	// necesita el residente para pedir un reset de confianza sobre esta
	// identidad -- ver persona.Handler.ResetHistorialContacto.
	PersonaID uint `json:"persona_id"`
}

// FindInvitadosFrecuentesPorCasa lista los invitados frecuentes (Rol =
// RolInvitadoFrecuente) de una casa -- cualquier residente activo de esa
// casa los ve y puede revocarlos, no solo quien los creó (misma casa,
// misma confianza que ya se comparte para aprobar/rechazar visitas).
func (r *MembresiaRepository) FindInvitadosFrecuentesPorCasa(tenantID uint, casaDestino string) ([]InvitadoFrecuenteFila, error) {
	var filas []InvitadoFrecuenteFila
	err := r.db.Table("membresias").
		Select("membresias.id AS id, personas.nombre AS nombre, personas.telefono AS telefono, membresias.persona_id AS persona_id").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Where("membresias.tenant_id = ? AND UPPER(membresias.casa_destino) = UPPER(?) AND membresias.rol = ? AND membresias.status = ?",
			tenantID, casaDestino, RolInvitadoFrecuente, ResidenteStatusActivo).
		Where("membresias.deleted_at IS NULL AND personas.deleted_at IS NULL").
		Order("membresias.created_at DESC").
		Scan(&filas).Error
	return filas, err
}

// RevocarInvitadoFrecuente hace soft-delete de un invitado frecuente,
// acotado a la misma casa y tenant de quien lo revoca -- evita que un
// residente de otra casa revoque el invitado frecuente de alguien más.
func (r *MembresiaRepository) RevocarInvitadoFrecuente(id, tenantID uint, casaDestino string) error {
	result := r.db.
		Where("tenant_id = ? AND UPPER(casa_destino) = UPPER(?) AND rol = ?", tenantID, casaDestino, RolInvitadoFrecuente).
		Delete(&Membresia{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// CompaneroCasa es una fila de FindCompanerosCasa — deliberadamente angosta:
// solo nombre y rol, nunca teléfono/CURP/foto. La restricción de privacidad
// vive en la query (Select explícito), no en un filtro posterior sobre un
// struct más amplio.
//
// Rol viaja explícitamente: sin él, un invitado frecuente (alguien a quien
// UN residente le dio acceso recurrente a SU casa, ver RolInvitadoFrecuente)
// se veía en esta lista exactamente igual que un compañero de vivienda real,
// sin ninguna forma de distinguirlos.
type CompaneroCasa struct {
	NombreCompleto string `json:"nombre_completo"`
	Rol            string `json:"rol"`
}

// FindCompanerosCasa lista los demás miembros activos de la misma casa,
// dentro del mismo tenant, excluyendo a excluirPersonaID (quien hace la
// consulta). Usado por Handler.ListarCompanerosCasa (paquete persona) para
// que un residente vea quién más vive con él.
func (r *MembresiaRepository) FindCompanerosCasa(tenantID uint, casaDestino string, excluirPersonaID uint) ([]CompaneroCasa, error) {
	list := make([]CompaneroCasa, 0)
	err := r.db.Table("membresias").
		Select("TRIM(COALESCE(personas.nombre, '') || ' ' || COALESCE(personas.apellido_paterno, '') || ' ' || COALESCE(personas.apellido_materno, '')) as nombre_completo, membresias.rol as rol").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Where("membresias.tenant_id = ? AND UPPER(TRIM(membresias.casa_destino)) = UPPER(TRIM(?)) AND membresias.status = ? AND membresias.persona_id != ? AND membresias.deleted_at IS NULL",
			tenantID, casaDestino, ResidenteStatusActivo, excluirPersonaID).
		Order("membresias.created_at ASC").
		Scan(&list).Error
	return list, err
}

// MembresiaPendienteConPersona es una fila de FindPendientesPorTenant —
// junta la Membresia con nombre/teléfono/foto de su Persona.
type MembresiaPendienteConPersona struct {
	ID              uint      `json:"id"`
	PersonaID       uint      `json:"persona_id" gorm:"column:persona_id"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno" gorm:"column:apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno" gorm:"column:apellido_materno"`
	Curp            string    `json:"curp" gorm:"column:curp"`
	Telefono        string    `json:"telefono" gorm:"column:telefono"`
	FotoCaraURL     string    `json:"foto_cara_url" gorm:"column:foto_cara_url"`
	FotoIneURL      string    `json:"foto_ine_url" gorm:"column:foto_ine_url"`
	TieneRostro     bool      `json:"tiene_rostro" gorm:"column:tiene_rostro"`
	TienePin        bool      `json:"tiene_pin" gorm:"column:tiene_pin"`
	CasaDestino     string    `json:"casa_destino" gorm:"column:casa_destino"`
	Status          string    `json:"status"`
	CreatedAt       time.Time `json:"created_at" gorm:"column:created_at"`
}

// FindPendientesPorTenant devuelve las membresías pendientes de aprobación de un
// tenant, con los datos de la Persona para que el admin pueda revisarla.
func (r *MembresiaRepository) FindPendientesPorTenant(tenantID uint) ([]MembresiaPendienteConPersona, error) {
	var list []MembresiaPendienteConPersona
	err := r.db.Table("membresias").
		Select("membresias.id as id, membresias.persona_id as persona_id, personas.nombre as nombre, personas.apellido_paterno as apellido_paterno, personas.apellido_materno as apellido_materno, "+
			"personas.curp as curp, personas.telefono as telefono, personas.foto_cara_url as foto_cara_url, personas.foto_ine_url as foto_ine_url, "+
			"(personas.embedding IS NOT NULL) as tiene_rostro, "+
			"(membresias.pin != '') as tiene_pin, "+
			"membresias.casa_destino as casa_destino, membresias.status as status, membresias.created_at as created_at").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Where("membresias.tenant_id = ? AND membresias.status = ? AND membresias.deleted_at IS NULL", tenantID, ResidenteStatusPendiente).
		Order("membresias.created_at DESC").
		Scan(&list).Error
	return list, err
}

// MembresiaActivaConPersona es una fila de FindActivasPorTenant — mismo
// shape que MembresiaPendienteConPersona, para la lista de residentes ya
// aprobados que ve el admin en el dashboard.
type MembresiaActivaConPersona struct {
	ID              uint      `json:"id"`
	PersonaID       uint      `json:"persona_id" gorm:"column:persona_id"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno" gorm:"column:apellido_paterno"`
	ApellidoMaterno string    `json:"apellido_materno" gorm:"column:apellido_materno"`
	Curp            string    `json:"curp" gorm:"column:curp"`
	Telefono        string    `json:"telefono" gorm:"column:telefono"`
	FotoCaraURL     string    `json:"foto_cara_url" gorm:"column:foto_cara_url"`
	FotoIneURL      string    `json:"foto_ine_url" gorm:"column:foto_ine_url"`
	TieneRostro     bool      `json:"tiene_rostro" gorm:"column:tiene_rostro"`
	TienePin        bool      `json:"tiene_pin" gorm:"column:tiene_pin"`
	CasaDestino     string    `json:"casa_destino" gorm:"column:casa_destino"`
	Status          string    `json:"status"`
	// Rol distingue un residente real de un invitado frecuente
	// (RolInvitadoFrecuente) -- antes no viajaba aquí y el dashboard no
	// tenía forma de saber cuáles de las membresías activas eran en
	// realidad invitados con acceso recurrente que un residente dio de
	// alta él mismo, sin pasar por la aprobación del admin.
	Rol       string    `json:"rol"`
	CreatedAt time.Time `json:"created_at" gorm:"column:created_at"`
	// EnroladoPorNombre solo viene lleno para un invitado frecuente -- el
	// residente que lo dio de alta (ver Membresia.CreadaPorPersonaID). Vacío
	// para una membresía de residente real (la aprobó el admin, no otra
	// Persona).
	EnroladoPorNombre string `json:"enrolado_por_nombre" gorm:"column:enrolado_por_nombre"`
	// Datos del Destino resuelto (join opcional -- nil/"" en membresías
	// viejas cuyo casa_destino no matcheó ningún Destino real, ver
	// migración 000064). La UI agrupa/ordena por estos cuando existen y
	// cae al texto de CasaDestino si no.
	DestinoID    *uint  `json:"destino_id" gorm:"column:destino_id"`
	DestinoCalle string `json:"destino_calle" gorm:"column:destino_calle"`
	DestinoTipo  string `json:"destino_tipo" gorm:"column:destino_tipo"`
}

// FindActivasPorTenant devuelve las membresías activas de un tenant.
func (r *MembresiaRepository) FindActivasPorTenant(tenantID uint) ([]MembresiaActivaConPersona, error) {
	var list []MembresiaActivaConPersona
	err := r.db.Table("membresias").
		Select("membresias.id as id, membresias.persona_id as persona_id, personas.nombre as nombre, personas.apellido_paterno as apellido_paterno, personas.apellido_materno as apellido_materno, "+
			"personas.curp as curp, personas.telefono as telefono, personas.foto_cara_url as foto_cara_url, personas.foto_ine_url as foto_ine_url, "+
			"(personas.embedding IS NOT NULL) as tiene_rostro, "+
			"(membresias.pin != '') as tiene_pin, "+
			"membresias.casa_destino as casa_destino, membresias.status as status, membresias.rol as rol, membresias.created_at as created_at, "+
			"membresias.destino_id as destino_id, destinos.calle as destino_calle, destinos.tipo as destino_tipo, "+
			"TRIM(COALESCE(enrolador.nombre, '') || ' ' || COALESCE(enrolador.apellido_paterno, '')) as enrolado_por_nombre").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Joins("LEFT JOIN destinos ON destinos.id = membresias.destino_id").
		Joins("LEFT JOIN personas AS enrolador ON enrolador.id = membresias.creada_por_persona_id").
		Where("membresias.tenant_id = ? AND membresias.status = ? AND membresias.deleted_at IS NULL", tenantID, ResidenteStatusActivo).
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

// RevocarPorTenant hace soft-delete de una o varias membresías, acotado al
// tenant de quien revoca -- un admin nunca puede revocar membresías de otro
// centro, ni por error de id ni maliciosamente. No borra la Persona: sigue
// pudiendo tener cuenta y membresías en otros tenants, y el historial de
// visitas conserva la referencia para auditoría.
func (r *MembresiaRepository) RevocarPorTenant(tenantID uint, ids []uint) (int64, error) {
	result := r.db.Where("tenant_id = ? AND id IN ?", tenantID, ids).Delete(&Membresia{})
	if result.Error != nil {
		return 0, result.Error
	}
	return result.RowsAffected, nil
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

// FindPinCodigosPorTenant devuelve los PIN en claro ya asignados dentro de
// un centro — el backend los usa para no repetir uno al generar el de una
// membresía nueva. Solo ve los generados por el sistema: las membresías
// viejas, con PIN elegido por la persona, tienen pin_codigo vacío y no
// entran en la comparación.
func (r *MembresiaRepository) FindPinCodigosPorTenant(tenantID uint) ([]string, error) {
	var codigos []string
	if err := r.db.Model(&Membresia{}).
		Where("tenant_id = ? AND pin_codigo != ''", tenantID).
		Pluck("pin_codigo", &codigos).Error; err != nil {
		return nil, err
	}
	return codigos, nil
}

// FindPinHashesLegacyPorTenant devuelve los hashes de las membresías del
// centro cuyo PIN eligió la persona antes de que el sistema empezara a
// generarlos: su código en claro no está guardado, así que la única forma
// de no repetirlo al generar uno nuevo es comparar contra el hash.
func (r *MembresiaRepository) FindPinHashesLegacyPorTenant(tenantID uint) ([]string, error) {
	var hashes []string
	if err := r.db.Model(&Membresia{}).
		Where("tenant_id = ? AND pin_codigo = '' AND pin != ''", tenantID).
		Pluck("pin", &hashes).Error; err != nil {
		return nil, err
	}
	return hashes, nil
}
