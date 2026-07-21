/*
Package visitas
Repositorio relacionado con modelo Visita

Operaciones CRUD en DB relacionadas solo con el dominio visitas
*/
package visitas

import "gorm.io/gorm"

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(v *Visita) error {
	return r.db.Create(v).Error
}

// joinVisitasDeAdmin arma el join contra accesos para acotar visitas al adminID dueño de esos accesos.
// Los métodos que escanean a Visita deben encadenar Select("visitas.*") para evitar que las columnas
// id/created_at del join corrompan el resultado.
func (r *Repository) joinVisitasDeAdmin(adminID uint) *gorm.DB {
	return r.db.Model(&Visita{}).
		Joins("JOIN accesos ON accesos.id = visitas.acceso_id").
		Where("accesos.admin_id = ?", adminID)
}

// VisitaFiltros acota el listado de ListarVisitas. Todos los campos son opcionales.
type VisitaFiltros struct {
	AccesoID      *uint
	TipoDocumento *TipoDocumento
	Estado        *EstadoVisita
	Q             string // ILIKE parcial sobre nombre, curp y clave_lector
}

func (r *Repository) FindAllByAdminID(
	adminID uint,
	filtros VisitaFiltros,
	page, pageSize int,
) ([]Visita, int64, error) {
	query := func() *gorm.DB {
		q := r.joinVisitasDeAdmin(adminID)
		if filtros.AccesoID != nil {
			q = q.Where("visitas.acceso_id = ?", *filtros.AccesoID)
		}
		if filtros.TipoDocumento != nil {
			q = q.Where("visitas.tipo_documento = ?", *filtros.TipoDocumento)
		}
		if filtros.Estado != nil {
			q = q.Where("visitas.estado = ?", *filtros.Estado)
		}
		if filtros.Q != "" {
			like := "%" + filtros.Q + "%"
			q = q.Where(
				`(visitas.nombre ILIKE ? OR visitas.curp ILIKE ? OR visitas.clave_lector ILIKE ?
				  OR visitas.casa_destino ILIKE ? OR visitas.placa ILIKE ?)`,
				like, like, like, like, like,
			)
		}
		return q
	}

	var total int64
	if err := query().Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	var list []Visita
	if err := query().
		Select("visitas.*").
		Order("visitas.created_at DESC").
		Limit(pageSize).
		Offset(offset).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	return list, total, nil
}

func (r *Repository) FindByIDAndAdminID(id, adminID uint) (*Visita, error) {
	var v Visita
	if err := r.joinVisitasDeAdmin(adminID).
		Select("visitas.*").
		Where("visitas.id = ?", id).
		First(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *Repository) FindByCurpAndAdminID(curp string, adminID uint) ([]Visita, error) {
	var list []Visita
	if err := r.joinVisitasDeAdmin(adminID).
		Select("visitas.*").
		Where("visitas.curp = ?", curp).
		Order("visitas.created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindPendientesByAccesoID devuelve las visitas PENDIENTE de aprobación para un acceso,
// usado por la app del residente.
func (r *Repository) FindPendientesByAccesoID(accesoID uint) ([]Visita, error) {
	var list []Visita
	if err := r.db.
		Where("acceso_id = ? AND estado = ?", accesoID, EstadoPendiente).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

func (r *Repository) UpdateEstado(id uint, estado EstadoVisita) error {
	result := r.db.Model(&Visita{}).Where("id = ?", id).Update("estado", estado)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
