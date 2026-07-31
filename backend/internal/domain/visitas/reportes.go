package visitas

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"gorm.io/gorm"
)

type ReporteIA struct {
	ID            uint `gorm:"primaryKey"`
	CreatedAt     time.Time
	PeriodoInicio time.Time `gorm:"not null"`
	PeriodoFin    time.Time `gorm:"not null"`
	Texto         string    `gorm:"not null"`
	DatosRaw      []byte    `gorm:"type:jsonb"`
}

func (ReporteIA) TableName() string { return "reportes_ia" }

type reporteRepository struct{ db *gorm.DB }

func (r *reporteRepository) guardar(reporte *ReporteIA) error {
	return r.db.Create(reporte).Error
}

func (r *reporteRepository) ultimos(n int) ([]ReporteIA, error) {
	var reportes []ReporteIA
	err := r.db.Order("created_at DESC").Limit(n).Find(&reportes).Error
	return reportes, err
}

// IniciarAgenteReportes lanza la goroutine del agente de reportes con ticker de 12h.
// Debe llamarse una sola vez al iniciar el servidor.
func IniciarAgenteReportes(db *gorm.DB, llmURL string) {
	repo := &reporteRepository{db: db}
	visitaRepo := NewRepository(db)

	go func() {
		ticker := time.NewTicker(12 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			generarReporte(repo, visitaRepo, llmURL)
		}
	}()
}

func generarReporte(repo *reporteRepository, visitaRepo *Repository, llmURL string) {
	fin := time.Now()
	inicio := fin.Add(-12 * time.Hour)

	vs, err := visitaRepo.ListarEnPeriodo(inicio, fin)
	if err != nil {
		log.Printf("[agente-reportes] error obteniendo visitas: %v", err)
		return
	}
	if len(vs) == 0 {
		return
	}

	datos := agregarDatos(vs)
	datosJSON, _ := json.Marshal(datos)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	sc := ScoreContexto{VecesVisitado: datos.TotalVisitas}
	texto, err := GenerarResumen(ctx, llmURL, sc)
	if err != nil {
		log.Printf("[agente-reportes] error LLM: %v", err)
		texto = resumirDatosTexto(datos)
	}

	_ = repo.guardar(&ReporteIA{
		PeriodoInicio: inicio,
		PeriodoFin:    fin,
		Texto:         texto,
		DatosRaw:      datosJSON,
	})
}

type datosAgregados struct {
	TotalVisitas int
	Aprobadas    int
	Rechazadas   int
	EnRevision   int
}

func agregarDatos(vs []Visita) datosAgregados {
	d := datosAgregados{TotalVisitas: len(vs)}
	for _, v := range vs {
		switch v.Estado {
		case EstadoAprobado:
			d.Aprobadas++
		case EstadoRechazado:
			d.Rechazadas++
		case EstadoRevision:
			d.EnRevision++
		}
	}
	return d
}

func resumirDatosTexto(d datosAgregados) string {
	return fmt.Sprintf(
		"Período de 12h: %d visitas totales. %d aprobadas, %d rechazadas, %d en revisión.",
		d.TotalVisitas, d.Aprobadas, d.Rechazadas, d.EnRevision,
	)
}
