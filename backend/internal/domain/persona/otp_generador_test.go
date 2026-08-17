package persona

import (
	"testing"
	"unicode"
)

func TestGenerarCodigoOtp_SeisDigitos(t *testing.T) {
	codigo, err := generarCodigoOtp()
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	if len(codigo) != 6 {
		t.Fatalf("esperaba código de 6 caracteres, got %d (%q)", len(codigo), codigo)
	}
	for _, c := range codigo {
		if !unicode.IsDigit(c) {
			t.Fatalf("esperaba solo dígitos, got %q", codigo)
		}
	}
}

func TestGenerarCodigoOtp_NoSiempreIgual(t *testing.T) {
	a, err := generarCodigoOtp()
	if err != nil {
		t.Fatalf("no esperaba error: %v", err)
	}
	distintos := false
	for i := 0; i < 20; i++ {
		b, err := generarCodigoOtp()
		if err != nil {
			t.Fatalf("no esperaba error: %v", err)
		}
		if b != a {
			distintos = true
			break
		}
	}
	if !distintos {
		t.Fatal("generarCodigoOtp devolvió el mismo código 20 veces seguidas — no es aleatorio")
	}
}
