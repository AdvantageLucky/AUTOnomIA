package visitas

import (
	"context"
	"testing"
)

func TestGenerarResumen_SinLLMURL_UsaHeuristico(t *testing.T) {
	s := ScoreContexto{VecesVisitado: 3, Confiable: true}
	texto, err := GenerarResumen(context.Background(), "", s)
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if texto == "" {
		t.Fatal("esperaba un resumen heurístico no vacío")
	}
}
