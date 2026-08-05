package residente

import (
	"context"
	"errors"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// WithContext retorna una instancia del repositorio vinculada al contexto HTTP de la petición
func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

// ByTenant es un GORM Scope que aísla las consultas usando el tenant_id del contexto
func ByTenant(db *gorm.DB) *gorm.DB {
	if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
		return db.Where("tenant_id = ?", tenantID)
	}
	return db
}

func (r *Repository) Create(res *Residente) error {
	return r.db.Create(res).Error
}

// FindByCasaAndKiosko busca al residente de una casa en un kiosko específico, usado para el login
func (r *Repository) FindByCasaAndKiosko(casaDestino string, kioskoID uint) (*Residente, error) {
	var res Residente
	if err := r.db.Scopes(ByTenant).
		Where("casa_destino = ? AND kiosko_id = ?", casaDestino, kioskoID).
		First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByID(id uint) (*Residente, error) {
	var res Residente
	if err := r.db.Scopes(ByTenant).First(&res, id).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByKioskoID(kioskoID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Scopes(ByTenant).Where("kiosko_id = ?", kioskoID).Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// VerificarOwnershipKiosko devuelve nil si el kiosko pertenece al admin; gorm.ErrRecordNotFound si no.
// Evita importar el paquete kiosko desde este dominio.
func (r *Repository) VerificarOwnershipKiosko(kioskoID, adminID uint) error {
	var count int64
	r.db.Scopes(ByTenant).Table("kioskos").
		Where("id = ? AND admin_id = ? AND deleted_at IS NULL", kioskoID, adminID).
		Count(&count)
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindPorPin busca al residente de un kiosko por PIN, comparando contra el hash almacenado.
// Itera sobre todos los residentes del kiosko para no exponer timing differences por bcrypt.
func (r *Repository) FindPorPin(kioskoID uint, pin string) (*Residente, error) {
	var list []Residente
	if err := r.db.Scopes(ByTenant).Where("kiosko_id = ?", kioskoID).Find(&list).Error; err != nil {
		return nil, err
	}
	for i := range list {
		if err := bcrypt.CompareHashAndPassword([]byte(list[i].Pin), []byte(pin)); err == nil {
			return &list[i], nil
		}
	}
	return nil, errors.New("pin incorrecto")
}

// FindAllByAdminID devuelve todos los residentes de todos los kioskos del admin.
// Requiere join con kioskos para acotar por admin_id (ver ADR-0015).
func (r *Repository) FindAllByAdminID(adminID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Scopes(ByTenant).
		Joins("JOIN kioskos ON kioskos.id = residentes.kiosko_id").
		Where("kioskos.admin_id = ? AND kioskos.deleted_at IS NULL", adminID).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}
