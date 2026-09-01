package visitas

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"gorm.io/gorm"
)

type ReporteIA struct {
	ID            uint            `gorm:"primaryKey"                      json:"id"`
	CreatedAt     time.Time       `json:"created_at"`
	TenantID      uint            `gorm:"column:tenant_id;not null;index" json:"tenant_id"`
	PeriodoInicio time.Time       `gorm:"not null"                        json:"periodo_inicio"`
	PeriodoFin    time.Time       `gorm:"not null"                        json:"periodo_fin"`
	Texto         string          `gorm:"not null"                        json:"texto"`
	DatosRaw      json.RawMessage `gorm:"type:jsonb"                      json:"datos_raw"`
}

func (ReporteIA) TableName() string { return "reportes_ia" }

type reporteRepository struct{ db *gorm.DB }

func (r *reporteRepository) guardar(reporte *ReporteIA) error {
	return r.db.Create(reporte).Error
}

// paginados devuelve los reportes ordenados del más reciente al más
// antiguo, con paginación — reemplaza a ultimos(n), que siempre traía un
// número fijo sin forma de ver más atrás.
func (r *reporteRepository) paginados(page, pageSize int) ([]ReporteIA, int64, error) {
	var total int64
	if err := r.db.Model(&ReporteIA{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}
	var reportes []ReporteIA
	offset := (page - 1) * pageSize
	err := r.db.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&reportes).Error
	return reportes, total, err
}

// IniciarAgenteReportes lanza la goroutine del agente de reportes con ticker de 12h.
// Debe llamarse una sola vez al iniciar el servidor.
func IniciarAgenteReportes(db *gorm.DB, llmURL string) {
	repo := &reporteRepository{db: db}
	visitaRepo := NewRepository(db)

	go func() {
		// Generar reporte inicial al arrancar el servidor
		generarReportesPorTenant(db, repo, visitaRepo, llmURL)

		ticker := time.NewTicker(12 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			generarReportesPorTenant(db, repo, visitaRepo, llmURL)
		}
	}()
}

// generarReportesPorTenant genera un ReporteIA independiente para cada
// CentroHabitacional activo — un reporte global mezclaría visitas de todos
// los tenants, que es justo lo que la multi-tenancy debe evitar.
func generarReportesPorTenant(db *gorm.DB, repo *reporteRepository, visitaRepo *Repository, llmURL string) {
	var tenantIDs []uint
	err := db.Table("centros_habitacionales").
		Where("deleted_at IS NULL").
		Pluck("id", &tenantIDs).Error
	if err != nil {
		log.Printf("[agente-reportes] error listando tenants: %v", err)
		return
	}

	for _, tenantID := range tenantIDs {
		generarReporte(repo, visitaRepo, llmURL, tenantID)
	}
}

func generarReporte(repo *reporteRepository, visitaRepo *Repository, llmURL string, tenantID uint) {
	fin := time.Now()
	inicio := fin.Add(-12 * time.Hour)

	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, tenantID)
	vs, err := visitaRepo.WithContext(ctx).ListarEnPeriodo(inicio, fin)
	if err != nil {
		log.Printf("[agente-reportes] tenant %d: error obteniendo visitas: %v", tenantID, err)
		return
	}
	if len(vs) == 0 {
		return
	}

	datos := agregarDatos(vs)
	datosJSON, _ := json.Marshal(datos)

	llmCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// GenerarResumenPeriodo y no GenerarResumen: esto describe un turno, no a
	// una persona. Antes se le pasaba un ScoreContexto inventado con las cifras
	// del periodo metidas en VecesVisitado, asi que al modelo se le pedia un
	// resumen "de este visitante" con datos que no eran de ningun visitante.
	texto, err := GenerarResumenPeriodo(llmCtx, llmURL, datos)
	if err != nil {
		log.Printf("[agente-reportes] tenant %d: error LLM: %v", tenantID, err)
	}

	if err := repo.guardar(&ReporteIA{
		TenantID:      tenantID,
		PeriodoInicio: inicio,
		PeriodoFin:    fin,
		Texto:         texto,
		DatosRaw:      datosJSON,
	}); err != nil {
		log.Printf("[agente-reportes] tenant %d: error guardando reporte: %v", tenantID, err)
	}
}

// visitaDestacada es una rechazada/en revisión concreta -- sin esto, el
// prompt solo tenía "2 rechazadas" como número suelto y el modelo llenaba el
// hueco de "qué pasó" inventando (mala suerte con nombres/motivos que nunca
// existieron). Dar las entradas reales que sí se pueden mencionar deja al
// modelo con algo concreto que decir en vez de un conteo que interpretar.
type visitaDestacada struct {
	Titular     string `json:"titular"`
	CasaDestino string `json:"casa_destino"`
	Hora        string `json:"hora"`
	Estado      string `json:"estado"`
}

type datosAgregados struct {
	TotalVisitas int            `json:"total_visitas"`
	Aprobadas    int            `json:"aprobadas"`
	Rechazadas   int            `json:"rechazadas"`
	EnRevision   int            `json:"en_revision"`
	PorTipo      map[string]int `json:"por_tipo"`     // RESIDENTE / INVITADO / VISITANTE
	Intervenidas int            `json:"intervenidas"` // marcadas para revisión por IA, sin importar el estado final
	// Hasta 5 rechazadas/en revisión, las más recientes primero -- ver
	// visitaDestacada. Vacía si no hubo ninguna.
	Destacadas []visitaDestacada `json:"destacadas"`
}

const maxDestacadas = 5

func agregarDatos(vs []Visita) datosAgregados {
	d := datosAgregados{TotalVisitas: len(vs), PorTipo: map[string]int{}}
	for _, v := range vs {
		switch v.Estado {
		case EstadoAprobado:
			d.Aprobadas++
		case EstadoRechazado:
			d.Rechazadas++
		case EstadoRevision:
			d.EnRevision++
		}
		d.PorTipo[string(v.TipoVisitante)]++
		if v.Intervenida {
			d.Intervenidas++
		}
		if (v.Estado == EstadoRechazado || v.Estado == EstadoRevision) && len(d.Destacadas) < maxDestacadas {
			d.Destacadas = append(d.Destacadas, visitaDestacada{
				Titular:     v.Titular,
				CasaDestino: v.CasaDestino,
				Hora:        v.CreatedAt.In(zonaMX).Format("15:04"),
				Estado:      string(v.Estado),
			})
		}
	}
	return d
}

func resumirDatosTexto(d datosAgregados) string {
	base := fmt.Sprintf(
		"Período de 12h: %d visitas totales. %d aprobadas, %d rechazadas, %d en revisión.",
		d.TotalVisitas, d.Aprobadas, d.Rechazadas, d.EnRevision,
	)
	if d.Intervenidas > 0 {
		base += fmt.Sprintf(" %d requirieron revisión de IA.", d.Intervenidas)
	}
	return base
}
