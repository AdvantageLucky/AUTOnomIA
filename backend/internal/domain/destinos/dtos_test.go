package destinos

import "testing"

func TestNombreDestino(t *testing.T) {
	casos := []struct {
		calle    string
		tipo     TipoDestino
		numero   string
		esperado string
	}{
		{"Calle Roble", TipoDestinoCasa, "12", "Calle Roble · Casa 12"},
		{"Av. Principal", TipoDestinoEdificio, "3B", "Av. Principal · Edificio 3B"},
	}
	for _, c := range casos {
		if got := nombreDestino(c.calle, c.tipo, c.numero); got != c.esperado {
			t.Errorf("nombreDestino(%q, %q, %q) = %q, esperaba %q", c.calle, c.tipo, c.numero, got, c.esperado)
		}
	}
}
