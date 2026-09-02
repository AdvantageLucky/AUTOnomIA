package visitas

import (
	"math"
	"testing"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"context"
)

func TestSimilitudCoseno(t *testing.T) {
	casos := []struct {
		nombre   string
		a, b     []float64
		esperado float64
	}{
		{"identicos", []float64{1, 0, 0}, []float64{1, 0, 0}, 1},
		{"opuestos", []float64{1, 0, 0}, []float64{-1, 0, 0}, -1},
		{"ortogonales", []float64{1, 0}, []float64{0, 1}, 0},
		{"misma direccion, otra magnitud", []float64{2, 4}, []float64{1, 2}, 1},
		{"dimensiones distintas", []float64{1, 0}, []float64{1, 0, 0}, -1},
		{"vacio", []float64{}, []float64{}, -1},
		{"norma cero", []float64{0, 0}, []float64{1, 1}, -1},
	}

	for _, c := range casos {
		t.Run(c.nombre, func(t *testing.T) {
			got := similitudCoseno(c.a, c.b)
			if math.Abs(got-c.esperado) > 1e-9 {
				t.Errorf("esperaba %v, got %v", c.esperado, got)
			}
		})
	}
}

// El caso que motivó guardar el embedding: sin CURP ni placa, un visitante
// recurrente aparecía como primera visita en cada entrada.
func TestHistorialDeVisitante_CaeARostroSinCurpNiPlaca(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	const tenantID = uint(1)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, tenantID)
	repoCtx := repo.WithContext(ctx)

	cara := []float64{1, 0, 0, 0}
	otraCara := []float64{0, 1, 0, 0}

	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", CasaDestino: "CASA 1", KioskoID: 1,
		Estado: EstadoAprobado, EmbeddingRostro: residente.FloatArray(cara),
	})
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", CasaDestino: "CASA 1", KioskoID: 1,
		Estado: EstadoAprobado, EmbeddingRostro: residente.FloatArray(cara),
	})
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Beto", CasaDestino: "CASA 2", KioskoID: 1,
		Estado: EstadoAprobado, EmbeddingRostro: residente.FloatArray(otraCara),
	})

	nueva := Visita{TenantID: tenantID, EmbeddingRostro: residente.FloatArray(cara)}
	historial, err := repoCtx.HistorialDeVisitante(nueva, 85, fuentesTodas)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historial) != 2 {
		t.Fatalf("esperaba las 2 entradas de Ana, got %d", len(historial))
	}
	for _, v := range historial {
		if v.Titular != "Ana" {
			t.Errorf("no debe traer entradas de otra persona, got %q", v.Titular)
		}
	}
}

// Sin embedding no se busca nada: traer el tenant entero le daría a un
// desconocido el historial (y los rechazos) de gente ajena.
func TestHistorialDeVisitante_SinIdentificadorNoTraeNada(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	const tenantID = uint(1)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, tenantID)
	repoCtx := repo.WithContext(ctx)

	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", CasaDestino: "CASA 1", KioskoID: 1,
		Estado: EstadoRechazado, EmbeddingRostro: residente.FloatArray([]float64{1, 0, 0, 0}),
	})

	historial, err := repoCtx.HistorialDeVisitante(Visita{TenantID: tenantID}, 85, fuentesTodas)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historial) != 0 {
		t.Errorf("sin identificador el historial debe venir vacio, got %d", len(historial))
	}
}

// El CURP manda sobre el rostro: si hay documento, es el identificador fuerte.
func TestHistorialDeVisitante_PrefiereCurpSobreRostro(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	const tenantID = uint(1)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, tenantID)
	repoCtx := repo.WithContext(ctx)

	cara := residente.FloatArray([]float64{1, 0, 0, 0})
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Ana", Curp: "GARJ900101HMCRNA01",
		CasaDestino: "CASA 1", KioskoID: 1, Estado: EstadoAprobado, EmbeddingRostro: cara,
	})
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Otra", CasaDestino: "CASA 9", KioskoID: 1,
		Estado: EstadoAprobado, EmbeddingRostro: cara,
	})

	nueva := Visita{TenantID: tenantID, Curp: "GARJ900101HMCRNA01", EmbeddingRostro: cara}
	historial, err := repoCtx.HistorialDeVisitante(nueva, 85, fuentesTodas)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(historial) != 1 || historial[0].Titular != "Ana" {
		t.Errorf("con CURP debe agrupar por CURP, no por rostro: %+v", historial)
	}
}

func TestHistorialPorRostro_RespetaElUmbral(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	const tenantID = uint(1)
	ctx := context.WithValue(context.Background(), ctxkeys.TenantID, tenantID)
	repoCtx := repo.WithContext(ctx)

	// Similitud coseno de ~0.894 con {1,0}: pasa un umbral de 85 pero no uno de 95.
	db.Create(&Visita{
		TenantID: tenantID, Titular: "Parecido", CasaDestino: "CASA 1", KioskoID: 1,
		Estado: EstadoAprobado, EmbeddingRostro: residente.FloatArray([]float64{2, 1}),
	})

	vivo := []float64{1, 0}

	laxo, err := repoCtx.HistorialPorRostro(vivo, 85)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(laxo) != 1 {
		t.Errorf("con umbral 85 debe coincidir, got %d", len(laxo))
	}

	estricto, err := repoCtx.HistorialPorRostro(vivo, 95)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(estricto) != 0 {
		t.Errorf("con umbral 95 no debe coincidir, got %d", len(estricto))
	}
}

func TestParsearEmbedding(t *testing.T) {
	if got := parsearEmbedding("[0.5,-0.25]"); len(got) != 2 || got[0] != 0.5 || got[1] != -0.25 {
		t.Errorf("esperaba el vector parseado, got %v", got)
	}
	// Un vector mal formado no debe tumbar el registro de la visita.
	for _, malo := range []string{"", "   ", "no-es-json", "[]", "{\"a\":1}"} {
		if got := parsearEmbedding(malo); got != nil {
			t.Errorf("esperaba nil para %q, got %v", malo, got)
		}
	}
}
