package visitas

import (
	"time"

	"kigo-autonomia-backend/internal/domain/kiosko"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(v *Visita) error {
	return r.db.Create(v).Error
}

// Los métodos que escanean a Visita deben encadenar Select("visitas.*") para evitar que las columnas
// id/created_at del join corrompan el resultado.
func (r *Repository) joinVisitasDeAdmin(adminID uint) *gorm.DB {
	return r.db.Model(&Visita{}).
		Joins("JOIN kioskos ON kioskos.id = visitas.kiosko_id").
		Where("kioskos.admin_id = ?", adminID)
}

// VisitaFiltros acota el listado de ListarVisitas. Todos los campos son opcionales.
type VisitaFiltros struct {
	KioskoID      *uint
	TipoDocumento *TipoDocumento
	Estado        *EstadoVisita
	Q             string // ILIKE parcial sobre titular, curp y clave_lector
}

func (r *Repository) FindAllByAdminID(
	adminID uint,
	filtros VisitaFiltros,
	page, pageSize int,
) ([]Visita, int64, error) {
	query := func() *gorm.DB {
		q := r.joinVisitasDeAdmin(adminID)
		if filtros.KioskoID != nil {
			q = q.Where("visitas.kiosko_id = ?", *filtros.KioskoID)
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
				`(visitas.titular ILIKE ? OR visitas.curp ILIKE ? OR visitas.clave_lector ILIKE ?
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

// FindByIDAndKioskoID busca una visita por ID, acotada al kiosko dueño.
// El filtro por kioskoID es necesario aunque el handler ya valide la sesion,
// para que un kiosko no pueda leer visitas de otro adivinando el ID.
func (r *Repository) FindByIDAndKioskoID(id, kioskoID uint) (*Visita, error) {
	var v Visita
	if err := r.db.
		Where("id = ? AND kiosko_id = ?", id, kioskoID).
		First(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}

// FindPendientesByKioskoID devuelve las visitas PENDIENTE de aprobación para un kiosko,
// usado por la app del residente.
func (r *Repository) FindPendientesByKioskoID(kioskoID uint) ([]Visita, error) {
	var list []Visita
	if err := r.db.
		Where("kiosko_id = ? AND estado = ?", kioskoID, EstadoPendiente).
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

// HistorialPorCURP devuelve visitas previas de un CURP, de más reciente a más antigua
func (r *Repository) HistorialPorCURP(curp string) ([]Visita, error) {
	var visitas []Visita
	err := r.db.Where("curp = ?", curp).Order("created_at DESC").Find(&visitas).Error
	return visitas, err
}

// ActualizarEstadoConScore actualiza estado e intervenida de una visita
func (r *Repository) ActualizarEstadoConScore(
	id uint,
	estado EstadoVisita,
	intervenida bool,
) error {
	return r.db.Model(&Visita{}).Where("id = ?", id).Updates(map[string]any{
		"estado":      estado,
		"intervenida": intervenida,
	}).Error
}

// GetKioskoConfig devuelve la config del kiosko, o valores por defecto si no existe aún
func (r *Repository) GetKioskoConfig(kioskoID uint) (*kiosko.KioskoConfig, error) {
	var cfg kiosko.KioskoConfig
	err := r.db.Where("kiosko_id = ?", kioskoID).First(&cfg).Error
	if err == gorm.ErrRecordNotFound {
		return &kiosko.KioskoConfig{AutoPassHabilitado: true, UmbralConfianzaVisitas: 5}, nil
	}
	return &cfg, err
}

// ListarEnPeriodo devuelve visitas creadas entre inicio y fin
func (r *Repository) ListarEnPeriodo(inicio, fin time.Time) ([]Visita, error) {
	var visitas []Visita
	err := r.db.Where("created_at BETWEEN ? AND ?", inicio, fin).Find(&visitas).Error
	return visitas, err
}
