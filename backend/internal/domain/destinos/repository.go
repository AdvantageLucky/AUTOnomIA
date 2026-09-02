package destinos

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

var ErrTenantNoResuelto = errors.New("tenant_id no resuelto en el contexto")

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

func (r *Repository) Create(d *Destino) error {
	return r.db.Create(d).Error
}

// CreateLote inserta varios destinos en una sola transacción — alta masiva
// desde el dashboard en vez de un POST por cada uno.
func (r *Repository) CreateLote(destinos []Destino) error {
	if len(destinos) == 0 {
		return nil
	}
	return r.db.Create(&destinos).Error
}

func (r *Repository) FindByTenantID(tenantID uint) ([]Destino, error) {
	if tenantID == 0 {
		return nil, ErrTenantNoResuelto
	}
	var list []Destino
	if err := r.db.Where("tenant_id = ?", tenantID).Order("nombre ASC").Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// CountResidentesPorDestino cuenta las membresías activas por destino_id —
// para la vista gráfica de "Destinos" del dashboard, que muestra cuántos
// residentes tiene cada casa. Consulta la tabla membresias directamente
// (sin importar el paquete residente, mismo motivo que otras consultas
// cross-dominio del proyecto: evitar un ciclo de imports).
func (r *Repository) CountResidentesPorDestino(tenantID uint) (map[uint]int, error) {
	var filas []struct {
		DestinoID uint
		Total     int
	}
	err := r.db.Table("membresias").
		Select("destino_id, count(*) as total").
		Where("tenant_id = ? AND status = 'activo' AND deleted_at IS NULL AND destino_id IS NOT NULL", tenantID).
		Group("destino_id").
		Scan(&filas).Error
	if err != nil {
		return nil, err
	}
	out := make(map[uint]int, len(filas))
	for _, f := range filas {
		out[f.DestinoID] = f.Total
	}
	return out, nil
}

// ListNombresByTenantID devuelve solo los nombres de los destinos del tenant,
// usado por el registro público de residentes para ofrecer un selector de casas.
func (r *Repository) ListNombresByTenantID(tenantID uint) ([]string, error) {
	if tenantID == 0 {
		return nil, ErrTenantNoResuelto
	}
	var nombres []string
	if err := r.db.Model(&Destino{}).
		Where("tenant_id = ?", tenantID).
		Order("nombre ASC").
		Pluck("nombre", &nombres).Error; err != nil {
		return nil, err
	}
	return nombres, nil
}

func (r *Repository) FindByNombreAndTenantID(nombre string, tenantID uint) (uint, error) {
	if tenantID == 0 {
		return 0, ErrTenantNoResuelto
	}
	var d Destino
	if err := r.db.Where("nombre = ? AND tenant_id = ?", nombre, tenantID).First(&d).Error; err != nil {
		return 0, err
	}
	return d.ID, nil
}

// FindCanonicoPorTenant busca un destino comparando sin distinguir mayúsculas
// ni espacios — quien escribe "casa destino" a mano en la app (sin picker,
// para no exponer el directorio completo por seguridad) fácilmente varía
// "102A" de "102a". Devuelve el registro real, cuyo Nombre exacto es el que
// debe quedar guardado, nunca lo que tecleó la persona.
func (r *Repository) FindCanonicoPorTenant(nombreLibre string, tenantID uint) (*Destino, error) {
	if tenantID == 0 {
		return nil, ErrTenantNoResuelto
	}
	var d Destino
	err := r.db.Where(
		"tenant_id = ? AND LOWER(TRIM(nombre)) = LOWER(TRIM(?))",
		tenantID, nombreLibre,
	).First(&d).Error
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *Repository) FindByID(id uint) (*Destino, error) {
	var d Destino
	if err := r.db.First(&d, id).Error; err != nil {
		return nil, err
	}
	return &d, nil
}

// UpdateContacto guarda el directorio de contacto sin verificar de un
// destino, escopeado por tenant.
func (r *Repository) UpdateContacto(id, tenantID uint, nombre, telefono string) error {
	if tenantID == 0 {
		return ErrTenantNoResuelto
	}
	result := r.db.Model(&Destino{}).
		Where("id = ? AND tenant_id = ?", id, tenantID).
		Updates(map[string]interface{}{
			"contacto_nombre":   nombre,
			"contacto_telefono": telefono,
		})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *Repository) Delete(id, tenantID uint) error {
	if tenantID == 0 {
		return ErrTenantNoResuelto
	}
	result := r.db.Where("id = ? AND tenant_id = ?", id, tenantID).Delete(&Destino{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
