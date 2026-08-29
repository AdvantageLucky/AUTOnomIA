package visitas

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestGenerarResumen_SinLLMURL_UsaHeuristico(t *testing.T) {
	s := ScoreContexto{VecesVisitado: 3, Confiable: true}
	texto, err := GenerarResumen(context.Background(), "", s)
	if err != nil {
		t.Fatalf("no esperaba error (sin LLM configurado no es una falla), got %v", err)
	}
	if texto == "" {
		t.Fatal("esperaba un resumen heurístico no vacío")
	}
}

func TestGenerarResumen_LLMFalla_DevuelveErrorYHeuristico(t *testing.T) {
	// Puerto que nadie escucha: la llamada falla de verdad, a diferencia de
	// simular con llmURL vacío (que ni siquiera intenta).
	s := ScoreContexto{VecesVisitado: 3}
	texto, err := GenerarResumen(context.Background(), "http://localhost:1", s)
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
	texto, err := GenerarResumen(context.Background(), srv.URL, s)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto != "Resumen real del LLM." {
		t.Errorf("esperaba el texto del LLM, got %q", texto)
	}
}
