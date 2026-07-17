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

// FindByCasaAndAcceso busca al residente de una casa en un acceso específico, usado para el login
func (r *Repository) FindByCasaAndAcceso(casaDestino string, accesoID uint) (*Residente, error) {
	var res Residente
	if err := r.db.
		Where("casa_destino = ? AND acceso_id = ?", casaDestino, accesoID).
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

func (r *Repository) FindByAccesoID(accesoID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Where("acceso_id = ?", accesoID).Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}
