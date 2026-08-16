package persona

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create guarda una Persona nueva, generando su qr_secreto si no lo trae ya
// (permite que el backfill del Task 5 fije uno determinístico en tests).
func (r *Repository) Create(p *Persona) error {
	if p.QrSecreto == "" {
		secreto, err := generarQrSecreto()
		if err != nil {
			return err
		}
		p.QrSecreto = secreto
	}
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
