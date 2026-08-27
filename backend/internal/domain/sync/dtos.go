package sync

// DestinoSnapshot es la forma reducida de un destino para el cache offline
// del kiosko — sin los campos administrativos que no usa la UI del kiosko.
type DestinoSnapshot struct {
	ID     uint   `json:"id"`
	Calle  string `json:"calle"`
	Tipo   string `json:"tipo"`
	Numero string `json:"numero"`
	Nombre string `json:"nombre"`
}

// ResidenteSnapshot trae el hash del PIN y el embedding — nunca el PIN en
// claro. Embedding va vacio (no null) cuando el residente no tiene huella
// facial capturada, para que el cliente Dart no tenga que distinguir null
// de lista vacia.
type ResidenteSnapshot struct {
	ID              uint      `json:"id"`
	Nombre          string    `json:"nombre"`
	ApellidoPaterno string    `json:"apellido_paterno"`
	CasaDestino     string    `json:"casa_destino"`
	PinHash         string    `json:"pin_hash"`
	Embedding       []float64 `json:"embedding"`
}

// InvitacionSnapshot trae el token: es la clave que el kiosko usa para
// reconocer y consumir la invitacion sin red.
type InvitacionSnapshot struct {
	Token       string  `json:"token"`
	Titular     string  `json:"titular"`
	CasaDestino string  `json:"casa_destino"`
	ExpiresAt   *string `json:"expires_at"`
}

type SnapshotResponse struct {
	Destinos     []DestinoSnapshot    `json:"destinos"`
	Residentes   []ResidenteSnapshot  `json:"residentes"`
	Invitaciones []InvitacionSnapshot `json:"invitaciones"`
}
