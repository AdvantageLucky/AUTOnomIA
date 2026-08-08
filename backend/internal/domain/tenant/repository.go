package tenant

import (
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	Create(tenant *CentroHabitacional) error
	FindByID(id uint) (*CentroHabitacional, error)
	Update(id uint, fields map[string]any) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(tenant *CentroHabitacional) error {
	return r.db.Create(tenant).Error
}

func (r *repository) FindByID(id uint) (*CentroHabitacional, error) {
	var tenant CentroHabitacional
	err := r.db.First(&tenant, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("centro habitacional no encontrado")
		}
		return nil, err
	}
	return &tenant, nil
}

func (r *repository) Update(id uint, fields map[string]any) error {
	return r.db.Model(&CentroHabitacional{}).Where("id = ?", id).Updates(fields).Error
}
