package seguridad

import (
	"context"

	"gorm.io/gorm"

	"kigo-autonomia-backend/internal/domain/residente"
)

const (
	TipoPinIncorrecto      = "pin_incorrecto"
	TipoQrInvalido         = "qr_invalido"
	TipoRostroNoReconocido = "rostro_no_reconocido"
)

// EventoSeguridad registra un intento de acceso fallido en el kiosko (PIN
// incorrecto, QR inválido) con evidencia fotográfica -- antes esto no
// dejaba ningún rastro: ni notificaba al admin ni guardaba quién lo
// intentó.
type EventoSeguridad struct {
	gorm.Model
	TenantID uint   `gorm:"column:tenant_id;not null;index"`
	KioskoID uint   `gorm:"column:kiosko_id;not null;index"`
	Tipo     string `gorm:"not null;index"`
	Detalle  string `gorm:"not null;default:''"`
	FotoURL  string `gorm:"column:foto_url;not null;default:''"`
	// EmbeddingRostro es la huella facial (192 flotantes, MobileFaceNet)
	// tomada en segundo plano al momento del intento fallido -- permite
	// correlacionar si la misma persona ya lo intentó antes, sin depender
	// de que esté dada de alta como Persona (ver ContarCorrelacionados).
	EmbeddingRostro residente.FloatArray `gorm:"column:embedding_rostro;type:float[]"`
	// IntentosPrevios se calcula una sola vez, al crear el evento (ver
	// Handler.Reportar) -- cuántos eventos ANTERIORES de este tenant
	// correlacionan por rostro con este. Igual que Visita.PersonaID, es más
	// barato resolverlo una vez que recalcularlo en cada lectura: el
	// dashboard hace polling de esta lista cada ~20s.
	IntentosPrevios int `gorm:"column:intentos_previos;not null;default:0"`
}

func (EventoSeguridad) TableName() string { return "eventos_seguridad" }

// EmailSender es una copia mínima de persona.EmailSender -- mismo criterio
// anti-dependencia-circular que ya se usa en otros paquetes de este repo
// (ver visitas/matching.go): no vale la pena un import cruzado por una
// interfaz de 3 líneas.
type EmailSender interface {
	Enviar(ctx context.Context, destino, asunto, cuerpo string) error
}

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

func (r *Repository) Crear(e *EventoSeguridad) error {
	return r.db.Create(e).Error
}

// EventoConNombre es el destino del join en ListarPorTenant -- mismo
// motivo que candidatoKioskoFila (persona/repository.go): un struct con
// nombre porque el Scan necesita mapear la columna extra "kiosko_nombre".
type EventoConNombre struct {
	EventoSeguridad
	KioskoNombre string
}

// ListarPorTenant trae los eventos de seguridad de un tenant, con el
// nombre del kiosko resuelto vía join, más recientes primero -- limitado a
// 200: esta pantalla es para atender lo reciente, no un reporte histórico.
func (r *Repository) ListarPorTenant(tenantID uint, tipo string) ([]EventoConNombre, error) {
	var list []EventoConNombre
	q := r.db.Table("eventos_seguridad").
		Select("eventos_seguridad.*, kioskos.nombre AS kiosko_nombre").
		Joins("JOIN kioskos ON kioskos.id = eventos_seguridad.kiosko_id").
		Where("eventos_seguridad.tenant_id = ?", tenantID).
		Where("eventos_seguridad.deleted_at IS NULL")
	if tipo != "" {
		q = q.Where("eventos_seguridad.tipo = ?", tipo)
	}
	err := q.Order("eventos_seguridad.created_at DESC").Limit(200).Scan(&list).Error
	return list, err
}

func (r *Repository) ContarPorTenant(tenantID uint) (int64, error) {
	var count int64
	err := r.db.Model(&EventoSeguridad{}).Where("tenant_id = ?", tenantID).Count(&count).Error
	return count, err
}

// CorreosAdminsDeTenant duplica persona.Repository.CorreosAdminsDeTenant --
// mismo motivo anti-ciclo que EmailSender arriba.
func (r *Repository) CorreosAdminsDeTenant(tenantID uint) ([]string, error) {
	var correos []string
	err := r.db.Table("admins").
		Where("tenant_id = ? AND rol = ?", tenantID, "admin").
		Pluck("correo", &correos).Error
	return correos, err
}
