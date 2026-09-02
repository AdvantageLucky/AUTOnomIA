package persona

import (
	"errors"

	"kigo-autonomia-backend/internal/domain/residente"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(p *Persona) error {
	return r.db.Create(p).Error
}

// Update guarda los cambios de una Persona ya existente — usado cuando una
// Persona "fantasma" (creada solo por teléfono, al ser invitada antes de
// haber usado Kigo) completa su perfil al registrarse de verdad.
func (r *Repository) Update(p *Persona) error {
	return r.db.Save(p).Error
}

func (r *Repository) UpdateDeviceToken(id uint, token string) error {
	return r.db.Model(&Persona{}).Where("id = ?", id).Update("device_token", token).Error
}

// FindActivasPorCasaDestino resuelve a quién notificar cuando llega una
// visita a una casa — reemplaza a residente.Repository.FindActivosPorCasaDestino
// (Residente ya no se llena para altas nuevas, ver spec 2026-08-26).
func (r *Repository) FindActivasPorCasaDestino(tenantID uint, casaDestino string) ([]Persona, error) {
	var list []Persona
	err := r.db.
		Joins("JOIN membresias ON membresias.persona_id = personas.id").
		Where("membresias.tenant_id = ? AND UPPER(membresias.casa_destino) = UPPER(?) AND membresias.status = ?",
			tenantID, casaDestino, residente.ResidenteStatusActivo).
		Where("membresias.deleted_at IS NULL").
		Find(&list).Error
	return list, err
}

// CorreosAdminsDeTenant consulta la tabla admins directamente (sin importar
// el paquete admin, mismo motivo que otras consultas cross-dominio del
// proyecto: evitar un ciclo de imports) para avisarles cuando una visita
// llega a un destino sin ningún residente al que notificar.
func (r *Repository) CorreosAdminsDeTenant(tenantID uint) ([]string, error) {
	var correos []string
	err := r.db.Table("admins").
		Where("tenant_id = ? AND rol = ?", tenantID, "admin").
		Pluck("correo", &correos).Error
	return correos, err
}

// ExisteVinculoKigoUserID resuelve si algún Persona ya está vinculada a esta
// cuenta de Kigo Parkimovil -- es todo lo que la mini-app del marketplace
// necesita saber (nunca el payload completo de Persona: kigo_user_id llega
// como input no verificado del lado del cliente, ver
// docs/integracion-kigo-marketplace-y-face-enrollment.md).
func (r *Repository) ExisteVinculoKigoUserID(kigoUserID string) (bool, error) {
	var count int64
	err := r.db.Model(&Persona{}).Where("kigo_user_id = ?", kigoUserID).Count(&count).Error
	return count > 0, err
}

func (r *Repository) FindByID(id uint) (*Persona, error) {
	var p Persona
	if err := r.db.First(&p, id).Error; err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *Repository) FindByTelefono(telefono string) (*Persona, error) {
	var p Persona
	if err := r.db.Where("telefono = ?", telefono).First(&p).Error; err != nil {
		return nil, err
	}
	return &p, nil
}

// FindOrCreateByTelefono busca una Persona por teléfono o crea una "en
// blanco" (sin nombre, sin verificar) si no existe — usado al invitar a
// alguien que nunca ha usado Kigo: se le crea un registro anclado a su
// teléfono, que se completa solo cuando esa persona se registre de verdad
// (VerificarOTP encuentra este mismo registro por FindByTelefono).
func (r *Repository) FindOrCreateByTelefono(telefono string) (*Persona, error) {
	p, err := r.FindByTelefono(telefono)
	if err == nil {
		return p, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}
	p = &Persona{Telefono: telefono}
	if err := r.Create(p); err != nil {
		return nil, err
	}
	return p, nil
}

// UpdateEmbedding guarda el embedding facial de una Persona — se llama
// cuando el kiosko manda un embedding junto con la verificación de QR
// (enrolamiento oportunista, ver Handler.VerificarQR).
func (r *Repository) UpdateEmbedding(id uint, embedding []float64) error {
	return r.db.Model(&Persona{}).Where("id = ?", id).
		Update("embedding", residente.FloatArray(embedding)).Error
}

// CandidatoKiosko es un residente activo candidato a que el kiosko lo
// reconozca por PIN o por rostro — reemplaza lo que antes leia
// de Residente, ahora sale de Persona+Membresia via join.
type CandidatoKiosko struct {
	MembresiaID     uint
	PersonaID       uint
	Nombre          string
	ApellidoPaterno string
	CasaDestino     string
	DestinoID       *uint
	PinHash         string
	Embedding       []float64
	// Rol distingue un residente real de un invitado frecuente
	// (residente.RolInvitadoFrecuente) -- sin esto, el kiosko no tenía
	// forma de saludar distinto a alguien que solo tiene acceso recurrente
	// prestado por un residente, y lo trataba como si fuera dueño de la
	// casa.
	Rol string
}

// candidatoKioskoFila es el destino intermedio del join en
// FindActivasPorTenant — un tipo con nombre (no un struct anónimo), porque
// GORM necesita poder resolver el esquema del campo Embedding
// (residente.FloatArray, con Value()/Scan() propios) y falla al hacerlo
// sobre un struct anónimo declarado inline.
type candidatoKioskoFila struct {
	MembresiaID     uint
	PersonaID       uint
	Nombre          string
	ApellidoPaterno string
	CasaDestino     string
	DestinoID       *uint
	PinHash         string
	Embedding       residente.FloatArray `gorm:"type:float[]"`
	Rol             string
}

// FindActivasPorTenant trae los candidatos de un tenant para el login del
// kiosko (PIN o rostro) y para el snapshot offline — un solo query
// reusado por los tres. Solo Membresias activas.
func (r *Repository) FindActivasPorTenant(tenantID uint) ([]CandidatoKiosko, error) {
	var filas []candidatoKioskoFila
	err := r.db.Table("membresias").
		Select("membresias.id AS membresia_id, membresias.persona_id AS persona_id, personas.nombre AS nombre, personas.apellido_paterno AS apellido_paterno, membresias.casa_destino AS casa_destino, membresias.destino_id AS destino_id, membresias.pin AS pin_hash, personas.embedding AS embedding, membresias.rol AS rol").
		Joins("JOIN personas ON personas.id = membresias.persona_id").
		Where("membresias.tenant_id = ? AND membresias.status = ?", tenantID, residente.ResidenteStatusActivo).
		Where("membresias.deleted_at IS NULL AND personas.deleted_at IS NULL").
		Scan(&filas).Error
	if err != nil {
		return nil, err
	}

	out := make([]CandidatoKiosko, len(filas))
	for i, f := range filas {
		out[i] = CandidatoKiosko{
			MembresiaID: f.MembresiaID, PersonaID: f.PersonaID, Nombre: f.Nombre, ApellidoPaterno: f.ApellidoPaterno,
			CasaDestino: f.CasaDestino, DestinoID: f.DestinoID, PinHash: f.PinHash, Embedding: []float64(f.Embedding),
			Rol: f.Rol,
		}
	}
	return out, nil
}
