package visitas

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func visitaDePrueba() Visita {
	return Visita{
		Titular:       "Ana Ruiz Mendoza",
		TipoVisitante: "VISITANTE",
		CasaDestino:   "Casa 12",
		Placa:         "ABC-123",
	}
}

func TestGenerarResumen_SinLLMURL_UsaHeuristico(t *testing.T) {
	s := ScoreContexto{VecesVisitado: 3, Confiable: true}
	texto, err := GenerarResumen(context.Background(), "", s, visitaDePrueba())
	if err != nil {
		t.Fatalf("no esperaba error (sin LLM configurado no es una falla), got %v", err)
	}
	if texto == "" {
		t.Fatal("esperaba un resumen heurístico no vacío")
	}
	// El heurístico tiene que decir quién llegó y a dónde: sin eso todos los
	// resúmenes de respaldo salen idénticos entre sí.
	if !strings.Contains(texto, "Ana Ruiz Mendoza") || !strings.Contains(texto, "Casa 12") {
		t.Errorf("esperaba nombre y destino en el heurístico, got %q", texto)
	}
}

func TestGenerarResumen_LLMFalla_DevuelveErrorYHeuristico(t *testing.T) {
	// Puerto que nadie escucha: la llamada falla de verdad, a diferencia de
	// simular con llmURL vacío (que ni siquiera intenta).
	s := ScoreContexto{VecesVisitado: 3}
	texto, err := GenerarResumen(context.Background(), "http://localhost:1", s, visitaDePrueba())
	if err == nil {
		t.Fatal("esperaba un error describiendo la falla del LLM, got nil")
	}
	if texto == "" {
		t.Fatal("esperaba que el texto siguiera trayendo el resumen heurístico pese al error")
	}
}

func TestGenerarResumen_LLMResponde_SinError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"content": "Resumen real del LLM."})
	}))
	defer srv.Close()

	s := ScoreContexto{VecesVisitado: 3}
	texto, err := GenerarResumen(context.Background(), srv.URL, s, visitaDePrueba())
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto != "Resumen real del LLM." {
		t.Errorf("esperaba el texto del LLM, got %q", texto)
	}
}

// El síntoma que se veía en el dashboard: el modelo devuelve el hueco sin
// rellenar. Publicarlo es peor que un texto más pobre pero cierto.
func TestGenerarResumen_LLMDevuelvePlaceholder_CaeAlHeuristico(t *testing.T) {
	casos := []string{
		"[nombre] llegó a [casa] sin incidencias.",
		"El visitante {nombre} va a la casa {casa}.",
		"<nombre del visitante> es recurrente.",
	}

	for _, contenido := range casos {
		t.Run(contenido, func(t *testing.T) {
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				json.NewEncoder(w).Encode(map[string]string{"content": contenido})
			}))
			defer srv.Close()

			s := ScoreContexto{VecesVisitado: 3}
			texto, err := GenerarResumen(context.Background(), srv.URL, s, visitaDePrueba())
			if err == nil {
				t.Error("esperaba un error avisando que el LLM devolvió placeholders")
			}
			if strings.ContainsAny(texto, "[{<") {
				t.Fatalf("no debe salir ningún placeholder al dashboard, got %q", texto)
			}
			if !strings.Contains(texto, "Ana Ruiz Mendoza") {
				t.Errorf("esperaba el heurístico como respaldo, got %q", texto)
			}
		})
	}
}

// El prompt viejo solo llevaba el conteo de visitas y las banderas, así que el
// modelo no tenía con qué escribir nada específico de esta visita.
func TestGenerarResumen_PromptLlevaLosDatosDeLaVisita(t *testing.T) {
	var recibido string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		recibido = string(body)
		json.NewEncoder(w).Encode(map[string]string{"content": "ok."})
	}))
	defer srv.Close()

	s := ScoreContexto{VecesVisitado: 2, AnomaliaMatricula: true}
	if _, err := GenerarResumen(context.Background(), srv.URL, s, visitaDePrueba()); err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}

	for _, esperado := range []string{"Ana Ruiz Mendoza", "Casa 12", "ABC-123", "placa distinta"} {
		if !strings.Contains(recibido, esperado) {
			t.Errorf("esperaba %q en el prompt, no está.\nPrompt: %s", esperado, recibido)
		}
	}
}

func TestGenerarResumenPeriodo_SinLLMURL_UsaCifras(t *testing.T) {
	d := datosAgregados{TotalVisitas: 10, Aprobadas: 7, Rechazadas: 2, EnRevision: 1}
	texto, err := GenerarResumenPeriodo(context.Background(), "", d)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if !strings.Contains(texto, "10") {
		t.Errorf("esperaba las cifras del período, got %q", texto)
	}
}

func TestGenerarResumenPeriodo_PromptLlevaLasCifras(t *testing.T) {
	var recibido string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		recibido = string(body)
		json.NewEncoder(w).Encode(map[string]string{"content": "Turno tranquilo."})
	}))
	defer srv.Close()

	d := datosAgregados{TotalVisitas: 10, Aprobadas: 7, Rechazadas: 2, EnRevision: 1}
	texto, err := GenerarResumenPeriodo(context.Background(), srv.URL, d)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto != "Turno tranquilo." {
		t.Errorf("esperaba el texto del LLM, got %q", texto)
	}
	if !strings.Contains(recibido, "Visitas totales: 10") {
		t.Errorf("esperaba las cifras del período en el prompt.\nPrompt: %s", recibido)
	}
}
