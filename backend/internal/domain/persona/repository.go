package persona

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(p *Persona) error {
	return r.db.Create(p).Error
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
