package residente

import (
	"math"
	"testing"
)

func aproximado(a, b float64) bool {
	return math.Abs(a-b) < 1e-9
}

func TestCosineSimilarity_VectoresIdenticos(t *testing.T) {
	a := []float64{1, 2, 3}
	score := cosineSimilarity(a, a)
	if !aproximado(score, 1) {
		t.Errorf("esperaba similitud 1 para vectores idénticos, got %f", score)
	}
}

func TestCosineSimilarity_VectoresOpuestos(t *testing.T) {
	a := []float64{1, 0}
	b := []float64{-1, 0}
	score := cosineSimilarity(a, b)
	if !aproximado(score, -1) {
		t.Errorf("esperaba similitud -1 para vectores opuestos, got %f", score)
	}
}

func TestCosineSimilarity_VectoresOrtogonales(t *testing.T) {
	a := []float64{1, 0}
	b := []float64{0, 1}
	score := cosineSimilarity(a, b)
	if !aproximado(score, 0) {
		t.Errorf("esperaba similitud 0 para vectores ortogonales, got %f", score)
	}
}

func TestCosineSimilarity_DimensionesDistintas(t *testing.T) {
	a := []float64{1, 2, 3}
	b := []float64{1, 2}
	if score := cosineSimilarity(a, b); score != -1 {
		t.Errorf("esperaba -1 con dimensiones distintas, got %f", score)
	}
}

func TestCosineSimilarity_VectorVacio(t *testing.T) {
	if score := cosineSimilarity(nil, nil); score != -1 {
		t.Errorf("esperaba -1 con vectores vacíos, got %f", score)
	}
}

func TestCosineSimilarity_NormaCero(t *testing.T) {
	a := []float64{0, 0, 0}
	b := []float64{1, 2, 3}
	if score := cosineSimilarity(a, b); score != -1 {
		t.Errorf("esperaba -1 con norma cero, got %f", score)
	}
}

func TestMejorCoincidencia_EligeElMasParecido(t *testing.T) {
	vivo := []float64{1, 0, 0}
	candidatos := []Residente{
		{Nombre: "Lejano", Embedding: []float64{0, 1, 0}},
		{Nombre: "Cercano", Embedding: []float64{0.98, 0.02, 0}},
		{Nombre: "Opuesto", Embedding: []float64{-1, 0, 0}},
	}

	mejor, score := mejorCoincidencia(candidatos, vivo)

	if mejor == nil || mejor.Nombre != "Cercano" {
		t.Fatalf("esperaba que 'Cercano' fuera el mejor match, got %+v", mejor)
	}
	if score <= 0.9 {
		t.Errorf("esperaba score alto para el match más cercano, got %f", score)
	}
}

func TestMejorCoincidencia_SinCandidatos(t *testing.T) {
	mejor, score := mejorCoincidencia(nil, []float64{1, 0, 0})
	if mejor != nil {
		t.Errorf("esperaba nil sin candidatos, got %+v", mejor)
	}
	if score != -1 {
		t.Errorf("esperaba score -1 sin candidatos, got %f", score)
	}
}

func TestMejorCoincidencia_IgnoraCandidatosDeOtraDimension(t *testing.T) {
	vivo := []float64{1, 0, 0}
	candidatos := []Residente{
		{Nombre: "DimensionVieja", Embedding: []float64{1, 0}},
		{Nombre: "Valido", Embedding: []float64{0.9, 0.1, 0}},
	}

	mejor, _ := mejorCoincidencia(candidatos, vivo)

	if mejor == nil || mejor.Nombre != "Valido" {
		t.Fatalf("esperaba que se ignorara el candidato de otra dimensión, got %+v", mejor)
	}
}
