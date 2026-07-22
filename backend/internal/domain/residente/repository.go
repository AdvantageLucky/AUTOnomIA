/*
Package residente
Repositorio relacionado con la tabla residentes

Funciones CRUD relacionadas solo con el dominio residente, es decir operaciones CRUD en tabla residentes
*/
package residente

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(res *Residente) error {
	return r.db.Create(res).Error
}

// FindByCasaAndKiosko busca al residente de una casa en un kiosko específico, usado para el login
func (r *Repository) FindByCasaAndKiosko(casaDestino string, kioskoID uint) (*Residente, error) {
	var res Residente
	if err := r.db.
		Where("casa_destino = ? AND kiosko_id = ?", casaDestino, kioskoID).
		First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByID(id uint) (*Residente, error) {
	var res Residente
	if err := r.db.First(&res, id).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByKioskoID(kioskoID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Where("kiosko_id = ?", kioskoID).Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// VerificarOwnershipKiosko devuelve nil si el kiosko pertenece al admin; gorm.ErrRecordNotFound si no.
// Evita importar el paquete kiosko desde este dominio.
func (r *Repository) VerificarOwnershipKiosko(kioskoID, adminID uint) error {
	var count int64
	r.db.Table("kioskos").
		Where("id = ? AND admin_id = ? AND deleted_at IS NULL", kioskoID, adminID).
		Count(&count)
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindAllByAdminID devuelve todos los residentes de todos los kioskos del admin.
// Requiere join con kioskos para acotar por admin_id (ver ADR-0015).
func (r *Repository) FindAllByAdminID(adminID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.
		Joins("JOIN kioskos ON kioskos.id = residentes.kiosko_id").
		Where("kioskos.admin_id = ? AND kioskos.deleted_at IS NULL", adminID).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}
