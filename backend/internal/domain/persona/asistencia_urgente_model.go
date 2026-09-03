package persona

import (
	"time"

	"gorm.io/gorm"
)

const (
	AsistenciaUrgenteEstadoPendiente = "pendiente"
	AsistenciaUrgenteEstadoResuelta  = "resuelta"
)

// AsistenciaUrgente registra cada solicitud de ayuda humana urgente desde un
// kiosko. Antes el aviso era 100% efímero (solo SSE al dashboard + correo,
// ver asistencia_urgente_handler.go): si el admin no tenía el dashboard
// abierto en ese instante exacto, la solicitud desaparecía sin dejar ningún
// registro consultable después -- este modelo es lo que faltaba para poder
// listarlas, ver el motivo y marcarlas como atendidas.
type AsistenciaUrgente struct {
	gorm.Model
	TenantID uint   `gorm:"column:tenant_id;not null;index"`
	KioskoID uint   `gorm:"column:kiosko_id;not null;index"`
	Motivo   string `gorm:"not null;default:''"`
	// Estado: pendiente | resuelta.
	Estado             string     `gorm:"not null;default:'pendiente'"`
	ResueltaPorAdminID *uint      `gorm:"column:resuelta_por_admin_id"`
	ResueltaAt         *time.Time `gorm:"column:resuelta_at"`
}

func (AsistenciaUrgente) TableName() string { return "asistencias_urgentes" }

// AsistenciaUrgenteConNombre es el destino del join en ListarPorTenant --
// mismo motivo que candidatoKioskoFila (persona/repository.go): un struct
// con nombre porque el Scan necesita mapear la columna extra "kiosko_nombre"
// (alias del join) además de las columnas propias de AsistenciaUrgente.
type AsistenciaUrgenteConNombre struct {
	AsistenciaUrgente
	KioskoNombre string
}

type AsistenciaUrgenteRepository struct {
	db *gorm.DB
}

func NewAsistenciaUrgenteRepository(db *gorm.DB) *AsistenciaUrgenteRepository {
	return &AsistenciaUrgenteRepository{db: db}
}

func (r *AsistenciaUrgenteRepository) Crear(a *AsistenciaUrgente) error {
	return r.db.Create(a).Error
}

// ListarPorTenant trae las solicitudes de un tenant, más recientes primero,
// con el nombre del kiosko resuelto vía join (el dashboard no debería tener
// que cruzarlo él mismo contra su propia lista de kioskos). Limitado a 200:
// esta pantalla es para atender lo reciente, no un reporte histórico.
func (r *AsistenciaUrgenteRepository) ListarPorTenant(tenantID uint, soloPendientes bool) ([]AsistenciaUrgenteConNombre, error) {
	var list []AsistenciaUrgenteConNombre
	q := r.db.Table("asistencias_urgentes").
		Select("asistencias_urgentes.*, kioskos.nombre AS kiosko_nombre").
		Joins("JOIN kioskos ON kioskos.id = asistencias_urgentes.kiosko_id").
		Where("asistencias_urgentes.tenant_id = ?", tenantID).
		Where("asistencias_urgentes.deleted_at IS NULL")
	if soloPendientes {
		q = q.Where("asistencias_urgentes.estado = ?", AsistenciaUrgenteEstadoPendiente)
	}
	err := q.Order("asistencias_urgentes.created_at DESC").Limit(200).Scan(&list).Error
	return list, err
}

func (r *AsistenciaUrgenteRepository) ContarPendientesPorTenant(tenantID uint) (int64, error) {
	var count int64
	err := r.db.Model(&AsistenciaUrgente{}).
		Where("tenant_id = ? AND estado = ?", tenantID, AsistenciaUrgenteEstadoPendiente).
		Count(&count).Error
	return count, err
}

// MarcarResuelta es un compare-and-set con scope de tenant: un admin no debe
// poder resolver la solicitud de otro tenant solo adivinando el ID.
func (r *AsistenciaUrgenteRepository) MarcarResuelta(id, tenantID, adminID uint) error {
	ahora := time.Now()
	res := r.db.Model(&AsistenciaUrgente{}).
		Where("id = ? AND tenant_id = ?", id, tenantID).
		Updates(map[string]any{
			"estado":                AsistenciaUrgenteEstadoResuelta,
			"resuelta_por_admin_id": adminID,
			"resuelta_at":           &ahora,
		})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
