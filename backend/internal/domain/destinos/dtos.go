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
	// ResidentesActivos solo lo llena ListarDestinos (vista admin) --
	// ListarDestinosPorAcceso es la que usa el kiosko, que no necesita ni
	// debe conocer ese número.
	ResidentesActivos int `json:"residentes_activos,omitempty"`
	// ContactoNombre/ContactoTelefono: directorio sin verificar que tecleó
	// el admin -- ver comentario en el modelo Destino. Solo va en la vista
	// admin, igual que ResidentesActivos.
	ContactoNombre   string `json:"contacto_nombre,omitempty"`
	ContactoTelefono string `json:"contacto_telefono,omitempty"`
}

// DestinoContactoRequest edita solo el directorio de contacto sin verificar
// de un destino ya existente -- separado de DestinoAdminRequest porque no
// toca calle/tipo/numero/titular.
type DestinoContactoRequest struct {
	ContactoNombre   string `json:"contacto_nombre"`
	ContactoTelefono string `json:"contacto_telefono"`
}

// DestinoKioskoResponse mantenido por compatibilidad con la app kiosko
type DestinoKioskoResponse = DestinoResponse

type DestinoAdminRequest struct {
	Calle   string `json:"calle"   binding:"required"`
	Tipo    string `json:"tipo"    binding:"required"`
	Numero  string `json:"numero"  binding:"required"`
	Titular string `json:"titular"`
}

// DestinoLoteItem es un destino del lote con su propio tipo, para poder dar
// de alta casas y departamentos de la misma calle en una sola operación.
type DestinoLoteItem struct {
	Tipo   string `json:"tipo"   binding:"required"`
	Numero string `json:"numero" binding:"required"`
}

// DestinoLoteRequest da de alta N destinos de una calle en una sola llamada —
// evita repetir el formulario 1 por 1 para un fraccionamiento con decenas de
// casas.
//
// Acepta dos formas. La nueva (Destinos) lleva el tipo por elemento: una calle
// puede tener n casas y m departamentos, y antes eso obligaba a mandar el
// formulario una vez por tipo. La vieja (Tipo + Numeros) se conserva porque es
// la que describe la mayoría de los altas — una tira de números del mismo tipo.
type DestinoLoteRequest struct {
	Calle    string            `json:"calle" binding:"required"`
	Tipo     string            `json:"tipo"`
	Numeros  []string          `json:"numeros"`
	Destinos []DestinoLoteItem `json:"destinos"`
}

// items normaliza las dos formas a una sola lista.
func (r DestinoLoteRequest) items() []DestinoLoteItem {
	if len(r.Destinos) > 0 {
		return r.Destinos
	}
	out := make([]DestinoLoteItem, 0, len(r.Numeros))
	for _, n := range r.Numeros {
		out = append(out, DestinoLoteItem{Tipo: r.Tipo, Numero: n})
	}
	return out
}

func toDestinoResponse(d Destino) DestinoResponse {
	return DestinoResponse{
		ID:               d.ID,
		Nombre:           d.Nombre,
		Calle:            d.Calle,
		Tipo:             string(d.Tipo),
		Numero:           d.Numero,
		Titular:          d.Titular,
		CreatedAt:        d.CreatedAt,
		ContactoNombre:   d.ContactoNombre,
		ContactoTelefono: d.ContactoTelefono,
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
