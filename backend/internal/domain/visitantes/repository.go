package visitantes

import (
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// Create crea un nuevo Visitante
func (r *Repository) Create(v *Visitante) error {
	return r.db.Create(v).Error
}

// Update actualiza la informacion de un Visitante usando el id del Acceso al que pertenece
func (r *Repository) Update(v *Visitante, accesoID uint) error {
	result := r.db.Where("acceso_id = ?", accesoID).Save(v)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// Delete elimina un Visitante usando su id y el id del Acceso al que pertenece
func (r *Repository) Delete(id, accesoID uint) error {
	result := r.db.Where("acceso_id = ?", accesoID).Delete(&Visitante{}, id)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// joinVisitantesDeAdmin arma el join contra accesos para acotar Visitantes al adminID dueño de esos accesos.
// No incluye Select aqui porque Count() no lo necesita; los metodos que escanean a Visitante (Find/First)
// deben encadenar Select("visitantes.*") ellos mismos: sin eso, el join trae tambien las columnas
// id/created_at/etc de accesos (ambas tablas embeben gorm.Model) y GORM las pisa al escanear, corrompiendo
// el ID del Visitante
func (r *Repository) joinVisitantesDeAdmin(adminID uint) *gorm.DB {
	return r.db.Model(&Visitante{}).
		Joins("JOIN accesos ON accesos.id = visitantes.acceso_id").
		Where("accesos.admin_id = ?", adminID)
}

// VisitanteFiltros acota el listado de ListarVisitantes. Todos los campos son opcionales (nil o
// cadena vacia = sin filtrar por ese campo); se combinan con AND entre ellos
type VisitanteFiltros struct {
	AccesoID      *uint
	TipoDocumento *TipoDocumento
	Q             string // texto libre: ILIKE parcial sobre nombre, curp y clave_lector (OR entre los 3)
}

// FindAllByAdminID encuentra, paginados, los Visitantes de los Accesos de un Admin que cumplan
// filtros (el JOIN de paso confirma que cada Acceso pertenece al admin, asi un admin no puede listar
// visitantes de un Acceso que no es suyo via acceso_id)
func (r *Repository) FindAllByAdminID(
	adminID uint,
	filtros VisitanteFiltros,
	page, pageSize int,
) ([]Visitante, int64, error) {
	query := func() *gorm.DB {
		q := r.joinVisitantesDeAdmin(adminID)
		if filtros.AccesoID != nil {
			q = q.Where("visitantes.acceso_id = ?", *filtros.AccesoID)
		}
		if filtros.TipoDocumento != nil {
			q = q.Where("visitantes.tipo_documento = ?", *filtros.TipoDocumento)
		}
		if filtros.Q != "" {
			like := "%" + filtros.Q + "%"
			q = q.Where(
				"(visitantes.nombre ILIKE ? OR visitantes.curp ILIKE ? OR visitantes.clave_lector ILIKE ?)",
				like,
				like,
				like,
			)
		}
		return q
	}

	var total int64
	// se usan cadenas independientes (no se reutiliza el *gorm.DB entre Count y Find) para que el
	// Select/Limit/Offset de una no contamine el statement de la otra
	if err := query().Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	var visitantes []Visitante
	if err := query().
		Select("visitantes.*").
		Order("visitantes.created_at DESC").
		Limit(pageSize).
		Offset(offset).
		Find(&visitantes).Error; err != nil {
		return nil, 0, err
	}

	return visitantes, total, nil
}

// FindByIDAndAdminID encuentra un Visitante por su id, en cualquier Acceso que pertenezca al Admin
func (r *Repository) FindByIDAndAdminID(id, adminID uint) (*Visitante, error) {
	var v Visitante
	if err := r.joinVisitantesDeAdmin(adminID).
		Select("visitantes.*").
		Where("visitantes.id = ?", id).
		First(&v).
		Error; err != nil {
		return nil, err
	}
	return &v, nil
}

// FindByCurpAndAdminID encuentra todas las visitas de una persona (por su CURP) en cualquier Acceso del
// Admin, util para saber si una persona ya visito antes y cuantas veces
func (r *Repository) FindByCurpAndAdminID(curp string, adminID uint) ([]Visitante, error) {
	var visitantes []Visitante
	if err := r.joinVisitantesDeAdmin(adminID).
		Select("visitantes.*").
		Where("visitantes.curp = ?", curp).
		Order("visitantes.created_at DESC").
		Find(&visitantes).Error; err != nil {
		return nil, err
	}
	return visitantes, nil
}
