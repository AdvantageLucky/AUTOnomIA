package persona

import (
	"testing"
	"unicode"

	"golang.org/x/crypto/bcrypt"
)

func TestGenerarPin_CincoDigitos(t *testing.T) {
	codigo, hash, err := generarPin(nil, nil)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(codigo) != pinDigitos {
		t.Fatalf("esperaba PIN de %d caracteres, got %d (%q)", pinDigitos, len(codigo), codigo)
	}
	for _, c := range codigo {
		if !unicode.IsDigit(c) {
			t.Fatalf("esperaba solo dígitos, got %q", codigo)
		}
	}
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(codigo)); err != nil {
		t.Fatalf("el hash devuelto no corresponde al código: %v", err)
	}
}

// Simula un centro que va creciendo: cada PIN nuevo entra a la lista de
// ocupados, y ninguno se puede repetir.
func TestGenerarPin_NuncaRepiteUnoOcupado(t *testing.T) {
	var usados []string
	vistos := map[string]bool{}
	for i := 0; i < 30; i++ {
		codigo, _, err := generarPin(usados, nil)
		if err != nil {
			t.Fatalf("no esperaba error en la iteración %d: %v", i, err)
		}
		if vistos[codigo] {
			t.Fatalf("PIN repetido en la iteración %d: %q", i, codigo)
		}
		vistos[codigo] = true
		usados = append(usados, codigo)
	}
}

func TestGenerarPin_SinEspacioFalla(t *testing.T) {
	usados := make([]string, 0, 100000)
	for i := 0; i < 100000; i++ {
		usados = append(usados, pinFijo(i))
	}
	if _, _, err := generarPin(usados, nil); err != errSinPinLibre {
		t.Fatalf("esperaba errSinPinLibre, got %v", err)
	}
}

// Los PIN anteriores a este cambio solo se conocen por su hash — es la
// única forma de descartarlos al generar uno nuevo.
func TestPinChocaConLegacy(t *testing.T) {
	h, err := bcrypt.GenerateFromPassword([]byte("90210"), bcrypt.MinCost)
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	hashes := []string{"", string(h)}
	if !pinChocaConLegacy("90210", hashes) {
		t.Fatal("esperaba choque con el PIN viejo 90210")
	}
	if pinChocaConLegacy("42731", hashes) {
		t.Fatal("42731 no está tomado, no debería chocar")
	}
}

func pinFijo(n int) string {
	d := []byte("00000")
	for i := 4; i >= 0; i-- {
		d[i] = byte('0' + n%10)
		n /= 10
	}
	return string(d)
}
