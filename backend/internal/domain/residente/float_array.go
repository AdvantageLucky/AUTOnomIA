package residente

import (
	"database/sql/driver"
	"fmt"
	"strconv"
	"strings"
)

// FloatArray es un []float64 que se lee/escribe como el literal nativo de un
// arreglo de Postgres (ej. "{0.12,-0.4,...}"). GORM con el driver pgx de este
// proyecto no serializa un []float64 plano como arreglo — lo manda como un
// "record" y Postgres lo rechaza — así que este tipo evita esa conversión
// automática e implementa Value()/Scan() a mano.
type FloatArray []float64

func (a FloatArray) Value() (driver.Value, error) {
	if a == nil {
		return nil, nil
	}
	partes := make([]string, len(a))
	for i, v := range a {
		partes[i] = strconv.FormatFloat(v, 'g', -1, 64)
	}
	return "{" + strings.Join(partes, ",") + "}", nil
}

func (a *FloatArray) Scan(src any) error {
	if src == nil {
		*a = nil
		return nil
	}

	var texto string
	switch v := src.(type) {
	case string:
		texto = v
	case []byte:
		texto = string(v)
	default:
		return fmt.Errorf("FloatArray.Scan: tipo no soportado %T", src)
	}

	texto = strings.Trim(texto, "{}")
	if texto == "" {
		*a = FloatArray{}
		return nil
	}

	partes := strings.Split(texto, ",")
	resultado := make(FloatArray, len(partes))
	for i, p := range partes {
		f, err := strconv.ParseFloat(strings.TrimSpace(p), 64)
		if err != nil {
			return fmt.Errorf("FloatArray.Scan: valor inválido %q: %w", p, err)
		}
		resultado[i] = f
	}
	*a = resultado
	return nil
}
