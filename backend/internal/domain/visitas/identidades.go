package visitas

import (
	"encoding/json"
	"sort"
	"strings"
	"time"
)

// maxVisitasParaIdentidades acota la agregación en memoria -- mismo
// criterio que maxVisitasEscaneadas en matching.go: con miles de visitas al
// mes, agregar el tenant completo en cada carga de la pantalla se vuelve
// caro, y las más recientes son las que le importan a un admin/residente
// decidiendo si resetear confianza hoy.
const maxVisitasParaIdentidades = 5000

// IdentidadResumen es una fila de "Identidades y confianza" -- agrupa todas
// las visitas de una misma identidad (Persona real, CURP, o un cluster de
// rostro cuando no hay ninguno de los dos) en un solo renglón con su
// conteo, última visita, foto y score más reciente.
type IdentidadResumen struct {
	PersonaID *uint  `json:"persona_id,omitempty"`
	Curp      string `json:"curp,omitempty"`
	// VisitaRepresentativaID identifica al cluster de rostro cuando no hay
	// PersonaID ni Curp -- "sin identificar, solo rostro" (ver
	// agregarIdentidades). El reset para este caso se pide contra esta
	// visita puntual: el backend resuelve su embedding y lo usa como clave
	// de comparación (ver Handler.ResetHistorialPorRostro).
	VisitaRepresentativaID *uint     `json:"visita_representativa_id,omitempty"`
	Nombre                 string    `json:"nombre"`
	TipoVisitante          string    `json:"tipo_visitante"`
	TipoDocumento          string    `json:"tipo_documento"`
	TotalVisitas           int       `json:"total_visitas"`
	UltimaVisita           time.Time `json:"ultima_visita"`
	// FotoURL es la foto (rostro, o documento si no hay rostro) de la
	// visita más reciente de esta identidad -- para reconocerla a simple
	// vista en la lista, sobre todo las identidades sin nombre.
	FotoURL string `json:"foto_url,omitempty"`
	// ScorePct es el score de confianza (0-100) de la visita más reciente
	// ya analizada -- nil si esa visita todavía no tiene análisis (la
	// goroutine de IA corre async, ver GuardarAnalisisIA) o si nunca se
	// calculó (visitas muy viejas, de antes del scoring).
	ScorePct *int `json:"score_pct,omitempty"`
}

// scoreIaParcial es lo único que hace falta leer de Visita.ScoreIA para
// esta pantalla -- no vale la pena importar el ScoreIA completo de
// analyzer.go por un solo campo.
type scoreIaParcial struct {
	ConfianzaPct int `json:"confianza_pct"`
}

func scorePctDe(v Visita) *int {
	if len(v.ScoreIA) == 0 {
		return nil
	}
	var s scoreIaParcial
	if err := json.Unmarshal(v.ScoreIA, &s); err != nil {
		return nil
	}
	return &s.ConfianzaPct
}

func fotoDe(v Visita) string {
	if v.FotoRostroURL != "" {
		return v.FotoRostroURL
	}
	return v.FotoDocumentoURL
}

// ListarIdentidadesConScore agrega, por tenant, todas las identidades con
// historial de visitas -- residentes y personas reales por PersonaID,
// visitantes sin cuenta por CURP, y visitantes sin ningún dato salvo su
// cara agrupados por similitud facial.
func (r *Repository) ListarIdentidadesConScore(tenantID uint) ([]IdentidadResumen, error) {
	var visitas []Visita
	if err := r.db.Where("tenant_id = ?", tenantID).
		Order("created_at DESC").
		Limit(maxVisitasParaIdentidades).
		Find(&visitas).Error; err != nil {
		return nil, err
	}
	return r.agregarIdentidades(visitas)
}

// ListarIdentidadesConScorePorCasa es el equivalente para un residente --
// acotado a las visitas dirigidas a su propia casa, mismo criterio de
// aislamiento que aplicarResetHistorial ("solo lo mío").
func (r *Repository) ListarIdentidadesConScorePorCasa(tenantID uint, casaDestino string) ([]IdentidadResumen, error) {
	casaDestino = strings.TrimSpace(casaDestino)
	if casaDestino == "" {
		return nil, nil
	}

	var visitas []Visita
	if err := r.db.Where("tenant_id = ? AND UPPER(casa_destino) = UPPER(?)", tenantID, casaDestino).
		Order("created_at DESC").
		Limit(maxVisitasParaIdentidades).
		Find(&visitas).Error; err != nil {
		return nil, err
	}
	return r.agregarIdentidades(visitas)
}

// umbralClusterRostro es el umbral de similitud coseno para agrupar dos
// visitas sin Persona ni CURP como "el mismo rostro" en esta lista -- mismo
// valor que el default de kiosko_configs.umbral_similitud_cara (85%, ver
// migración 000076). Esta pantalla no tiene el umbral configurado del
// tenant a la mano (agrega across kioskos), así que usa ese default fijo
// por coherencia con el resto del sistema.
const umbralClusterRostro = 0.85

// agregarIdentidades hace el trabajo real de las dos funciones de arriba --
// se agrega en memoria (no con SQL específico de Postgres como DISTINCT ON)
// para que corra igual sobre el SQLite en memoria que usan los tests de
// este paquete.
func (r *Repository) agregarIdentidades(visitas []Visita) ([]IdentidadResumen, error) {
	var personaIDs []uint
	vistoPersona := map[uint]bool{}
	for _, v := range visitas {
		if v.PersonaID != nil && !vistoPersona[*v.PersonaID] {
			vistoPersona[*v.PersonaID] = true
			personaIDs = append(personaIDs, *v.PersonaID)
		}
	}
	nombresPersona := map[uint]string{}
	if len(personaIDs) > 0 {
		var filas []struct {
			ID              uint
			Nombre          string
			ApellidoPaterno string
		}
		if err := r.db.Table("personas").
			Select("id, nombre, apellido_paterno").
			Where("id IN ?", personaIDs).
			Scan(&filas).Error; err != nil {
			return nil, err
		}
		for _, f := range filas {
			nombresPersona[f.ID] = strings.TrimSpace(f.Nombre + " " + f.ApellidoPaterno)
		}
	}

	porPersona := map[uint]*IdentidadResumen{}
	var ordenPersona []uint
	porCurp := map[string]*IdentidadResumen{}
	var ordenCurp []string
	// Clusters de solo-rostro: se resuelven aparte al final (ver abajo),
	// porque a diferencia de persona_id/curp no hay una clave exacta con la
	// que indexar un map -- hay que compararlas todas contra todas.
	var soloRostro []Visita

	for _, v := range visitas {
		if v.PersonaID != nil {
			id := *v.PersonaID
			resumen, ok := porPersona[id]
			if !ok {
				nombre := nombresPersona[id]
				if nombre == "" {
					nombre = v.Titular
				}
				idCopy := id
				resumen = &IdentidadResumen{
					PersonaID: &idCopy, Nombre: nombre,
					TipoVisitante: string(v.TipoVisitante), TipoDocumento: string(v.TipoDocumento),
					UltimaVisita: v.CreatedAt, FotoURL: fotoDe(v), ScorePct: scorePctDe(v),
				}
				porPersona[id] = resumen
				ordenPersona = append(ordenPersona, id)
			}
			resumen.TotalVisitas++
			continue
		}
		if v.Curp != "" {
			resumen, ok := porCurp[v.Curp]
			if !ok {
				resumen = &IdentidadResumen{
					Curp: v.Curp, Nombre: v.Titular,
					TipoVisitante: string(v.TipoVisitante), TipoDocumento: string(v.TipoDocumento),
					UltimaVisita: v.CreatedAt, FotoURL: fotoDe(v), ScorePct: scorePctDe(v),
				}
				porCurp[v.Curp] = resumen
				ordenCurp = append(ordenCurp, v.Curp)
			}
			resumen.TotalVisitas++
			continue
		}
		if len(v.EmbeddingRostro) > 0 {
			soloRostro = append(soloRostro, v)
		}
		// Ni persona_id, ni CURP, ni embedding: no hay nada con qué agrupar
		// esta visita (p. ej. un acceso solo por placa) -- se omite.
	}

	resultado := make([]IdentidadResumen, 0, len(ordenPersona)+len(ordenCurp)+len(soloRostro))
	for _, id := range ordenPersona {
		resultado = append(resultado, *porPersona[id])
	}
	for _, c := range ordenCurp {
		resultado = append(resultado, *porCurp[c])
	}
	resultado = append(resultado, clusterizarSoloRostro(soloRostro)...)

	sort.Slice(resultado, func(i, j int) bool {
		return resultado[i].UltimaVisita.After(resultado[j].UltimaVisita)
	})
	return resultado, nil
}

// clusterizarSoloRostro agrupa visitas sin Persona ni CURP por similitud
// facial -- greedy, no un clustering "de verdad": cada visita se compara
// contra el representante (la primera) de cada cluster ya armado, y se une
// al primero que supere el umbral o abre uno nuevo. [visitas] ya viene
// ordenado más reciente primero (mismo orden que agregarIdentidades recibe),
// así que el representante de cada cluster es siempre su visita más
// reciente -- la foto y el score que se muestran son los más frescos.
func clusterizarSoloRostro(visitas []Visita) []IdentidadResumen {
	type cluster struct {
		representante Visita
		total         int
	}
	var clusters []*cluster

	for _, v := range visitas {
		asignado := false
		for _, c := range clusters {
			if similitudCoseno(c.representante.EmbeddingRostro, v.EmbeddingRostro) >= umbralClusterRostro {
				c.total++
				asignado = true
				break
			}
		}
		if !asignado {
			clusters = append(clusters, &cluster{representante: v, total: 1})
		}
	}

	resultado := make([]IdentidadResumen, 0, len(clusters))
	for _, c := range clusters {
		v := c.representante
		id := v.ID
		resultado = append(resultado, IdentidadResumen{
			VisitaRepresentativaID: &id,
			Nombre:                 "",
			TipoVisitante:          string(v.TipoVisitante),
			TipoDocumento:          string(v.TipoDocumento),
			TotalVisitas:           c.total,
			UltimaVisita:           v.CreatedAt,
			FotoURL:                fotoDe(v),
			ScorePct:               scorePctDe(v),
		})
	}
	return resultado
}
