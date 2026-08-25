package residente

import (
	"context"
	"errors"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// WithContext retorna una instancia del repositorio vinculada al contexto HTTP de la petición
func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

// ByTenant filtra por el tenant del contexto. Para queries sin JOIN.
func ByTenant(db *gorm.DB) *gorm.DB {
	if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
		return db.Where("tenant_id = ?", tenantID)
	}
	return db
}

// ByTenantFor devuelve un scope que califica tenant_id con el nombre de tabla dado.
// Usar en queries con JOIN para evitar SQLSTATE 42702 (columna ambigua).
func ByTenantFor(table string) func(*gorm.DB) *gorm.DB {
	return func(db *gorm.DB) *gorm.DB {
		if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
			return db.Where(table+".tenant_id = ?", tenantID)
		}
		return db
	}
}

func (r *Repository) Create(res *Residente) error {
	return r.db.Create(res).Error
}

// FindByCasaAndKiosko busca al residente de una casa en un kiosko específico, usado para el login
func (r *Repository) FindByCasaAndKiosko(casaDestino string, kioskoID uint) (*Residente, error) {
	var res Residente
	if err := r.db.Scopes(ByTenant).
		Where("casa_destino = ? AND kiosko_id = ?", casaDestino, kioskoID).
		First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByID(id uint) (*Residente, error) {
	var res Residente
	if err := r.db.Scopes(ByTenant).First(&res, id).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByTenantAndID(tenantID, id uint) (*Residente, error) {
	var res Residente
	if err := r.db.Where("tenant_id = ? AND id = ?", tenantID, id).First(&res).Error; err != nil {
		return nil, err
	}
	return &res, nil
}

func (r *Repository) FindByKioskoID(kioskoID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Scopes(ByTenant).Where("kiosko_id = ?", kioskoID).Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// VerificarOwnershipKiosko devuelve nil si el kiosko pertenece al admin; gorm.ErrRecordNotFound si no.
func (r *Repository) VerificarOwnershipKiosko(kioskoID, adminID uint) error {
	var count int64
	r.db.Scopes(ByTenant).Table("kioskos").
		Where("id = ? AND admin_id = ? AND deleted_at IS NULL", kioskoID, adminID).
		Count(&count)
	if count == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// FindPorPin busca al residente activo de un tenant por PIN con bcrypt.
// Itera sobre todos los activos del tenant para no exponer timing differences.
func (r *Repository) FindPorPin(tenantID uint, pin string) (*Residente, error) {
	var list []Residente
	if err := r.db.
		Where("tenant_id = ? AND status = ?", tenantID, ResidenteStatusActivo).
		Find(&list).Error; err != nil {
		return nil, err
	}
	for i := range list {
		if err := bcrypt.CompareHashAndPassword([]byte(list[i].Pin), []byte(pin)); err == nil {
			return &list[i], nil
		}
	}
	return nil, errors.New("pin incorrecto")
}

// FindActivosConEmbeddingPorTenant devuelve los residentes activos de un tenant que
// ya tienen una huella facial (embedding) calculada, candidatos para comparar
// contra un rostro capturado en vivo.
func (r *Repository) FindActivosConEmbeddingPorTenant(tenantID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.
		Where("tenant_id = ? AND status = ? AND embedding IS NOT NULL", tenantID, ResidenteStatusActivo).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindActivosPorCasaDestino devuelve los residentes activos de una casa dentro
// de un tenant — usado para decidir a quién notificar cuando llega una visita.
func (r *Repository) FindActivosPorCasaDestino(tenantID uint, casaDestino string) ([]Residente, error) {
	var list []Residente
	if err := r.db.
		Where("tenant_id = ? AND casa_destino = ? AND status = ?", tenantID, casaDestino, ResidenteStatusActivo).
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// UpdateDeviceToken guarda el token FCM del dispositivo de la app residente.
func (r *Repository) UpdateDeviceToken(id uint, token string) error {
	return r.db.Model(&Residente{}).Where("id = ?", id).Update("device_token", token).Error
}

// FindPendientesPorTenant devuelve residentes con status=pendiente del tenant.
func (r *Repository) FindPendientesPorTenant(tenantID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.
		Where("tenant_id = ? AND status = ?", tenantID, ResidenteStatusPendiente).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// UpdateStatus cambia el status de un residente.
func (r *Repository) UpdateStatus(id uint, status string) error {
	return r.db.Model(&Residente{}).Where("id = ?", id).Update("status", status).Error
}

// FindAllByAdminID devuelve todos los residentes activos del tenant del admin.
//
// Bug anterior: usaba INNER JOIN kioskos ON kioskos.id = residentes.kiosko_id,
// lo que descartaba silenciosamente a todos los residentes con kiosko_id NULL
// (auto-registros aprobados que aún no tienen kiosko asignado).
// La solución correcta es filtrar por tenant_id + status directamente.
func (r *Repository) FindAllByAdminID(adminID uint) ([]Residente, error) {
	var list []Residente
	if err := r.db.Scopes(ByTenant).
		Where("status = ?", ResidenteStatusActivo).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}


// BuscarCentroPorCodigo devuelve el id y nombre del centro con ese código público.
func (r *Repository) BuscarCentroPorCodigo(codigo string) (id uint, nombre, direccion string, err error) {
	row := r.db.Table("centros_habitacionales").
		Select("id, nombre, direccion").
		Where("codigo = ? AND deleted_at IS NULL", codigo).
		Row()
	err = row.Scan(&id, &nombre, &direccion)
	return
}

// FindPorPinPublico valida el PIN de un residente activo por tenant + casa_destino sin depender del contexto.
func (r *Repository) FindPorPinPublico(tenantID uint, casaDestino, pin string) (*Residente, error) {
	var list []Residente
	if err := r.db.
		Where("tenant_id = ? AND casa_destino = ? AND status IN ?",
			tenantID, casaDestino,
			[]string{ResidenteStatusActivo, ResidenteStatusPendiente}).
		Find(&list).Error; err != nil {
		return nil, err
	}
	for i := range list {
		if err := bcrypt.CompareHashAndPassword([]byte(list[i].Pin), []byte(pin)); err == nil {
			return &list[i], nil
		}
	}
	return nil, errors.New("credenciales incorrectas")
}
