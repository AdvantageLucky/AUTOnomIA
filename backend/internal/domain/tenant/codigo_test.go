package tenant

import "testing"

func TestGenerarCodigo(t *testing.T) {
	casos := map[string]string{
		"Residencial Las Palmas": "RESIDENCIAL-LAS-PALMAS",
		"Fraccionamiento Ñandú":  "FRACCIONAMIENTO-NANDU",
		"  espacios   dobles  ":  "ESPACIOS-DOBLES",
		"FEPRO-2026":             "FEPRO-2026",
		"@@@":                    "CENTRO",
		"":                       "CENTRO",
	}
	for nombre, esperado := range casos {
		if got := GenerarCodigo(nombre); got != esperado {
			t.Errorf("GenerarCodigo(%q) = %q, esperaba %q", nombre, got, esperado)
		}
	}
}

func TestGenerarCodigo_TruncaLargo(t *testing.T) {
	nombre := "Un Centro Habitacional Con Un Nombre Extremadamente Largo Para Probar El Truncado"
	got := GenerarCodigo(nombre)
	if len(got) > codigoLongitudMax {
		t.Errorf("GenerarCodigo produjo %d caracteres, esperaba <= %d", len(got), codigoLongitudMax)
	}
	if got[len(got)-1] == '-' {
		t.Errorf("GenerarCodigo(%q) = %q termina en guion tras truncar", nombre, got)
	}
}
