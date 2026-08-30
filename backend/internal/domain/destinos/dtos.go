package destinos

import "time"

type DestinoResponse struct {
	ID        uint      `json:"id"`
	Nombre    string    `json:"nombre"`
	Calle     string    `json:"calle"`
	Tipo      string    `json:"tipo"`
	Numero    string    `json:"numero"`
	Titular   string    `json:"titular"`
	CreatedAt time.Time `json:"created_at"`
}

// DestinoKioskoResponse mantenido por compatibilidad con la app kiosko
type DestinoKioskoResponse = DestinoResponse

type DestinoAdminRequest struct {
	Calle   string `json:"calle"   binding:"required"`
	Tipo    string `json:"tipo"    binding:"required"`
	Numero  string `json:"numero"  binding:"required"`
	Titular string `json:"titular"`
}

// DestinoLoteRequest da de alta N destinos de una vez: misma calle y tipo,
// un número distinto por cada uno — evita repetir el formulario 1 por 1
// para un fraccionamiento con decenas de casas.
type DestinoLoteRequest struct {
	Calle   string   `json:"calle"   binding:"required"`
	Tipo    string   `json:"tipo"    binding:"required"`
	Numeros []string `json:"numeros" binding:"required,min=1,dive,required"`
}

func toDestinoResponse(d Destino) DestinoResponse {
	return DestinoResponse{
		ID:        d.ID,
		Nombre:    d.Nombre,
		Calle:     d.Calle,
		Tipo:      string(d.Tipo),
		Numero:    d.Numero,
		Titular:   d.Titular,
		CreatedAt: d.CreatedAt,
	}
}

// toDestinoKioskoResponse mantenido por compatibilidad
var toDestinoKioskoResponse = toDestinoResponse

func tipoDisplay(tipo TipoDestino) string {
	t := string(tipo)
	if len(t) == 0 {
		return "Casa"
	}
	switch t {
	case "casa":
		return "Casa"
	case "departamento":
		return "Depto"
	case "edificio":
		return "Edificio"
	case "oficina":
		return "Oficina"
	case "local":
		return "Local"
	case "bodega":
		return "Bodega"
	case "lote":
		return "Lote"
	default:
		return t
	}
}

// nombreDestino arma el string resuelto que viaja como casa_destino por el
// resto del sistema — ej. "Calle Roble · Casa 12".
func nombreDestino(calle string, tipo TipoDestino, numero string) string {
	return calle + " · " + tipoDisplay(tipo) + " " + numero
}
