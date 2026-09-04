package visitas

import (
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
// las visitas de una misma identidad (Persona real, o CURP cuando no hay
// cuenta) en un solo renglón con su conteo y última visita.
//
// Deliberadamente NO incluye visitantes identificados solo por rostro (sin
// CURP, sin cuenta, sin invitación): ese caso no tiene hoy ningún
// identificador estable contra el que anclar un reset (se agrupa por
// similitud facial calculada al vuelo, no por una clave persistida) --
// listarlos con un botón de "resetear" que no podría funcionar sería peor
// que no listarlos. Ver HistorialReset.Curp para el resto de los casos.
type IdentidadResumen struct {
	PersonaID     *uint     `json:"persona_id,omitempty"`
	Curp          string    `json:"curp,omitempty"`
	Nombre        string    `json:"nombre"`
	TipoVisitante string    `json:"tipo_visitante"`
	TipoDocumento string    `json:"tipo_documento"`
	TotalVisitas  int       `json:"total_visitas"`
	UltimaVisita  time.Time `json:"ultima_visita"`
}

// ListarIdentidadesConScore agrega, por tenant, todas las identidades con
// historial de visitas -- residentes y personas reales por PersonaID,
// visitantes sin cuenta por CURP.
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
					UltimaVisita: v.CreatedAt,
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
					UltimaVisita: v.CreatedAt,
				}
				porCurp[v.Curp] = resumen
				ordenCurp = append(ordenCurp, v.Curp)
			}
			resumen.TotalVisitas++
		}
		// Sin persona_id y sin CURP: identidad solo-rostro sin identificador
		// estable -- se omite a propósito (ver doc de IdentidadResumen).
	}

	resultado := make([]IdentidadResumen, 0, len(ordenPersona)+len(ordenCurp))
	for _, id := range ordenPersona {
		resultado = append(resultado, *porPersona[id])
	}
	for _, c := range ordenCurp {
		resultado = append(resultado, *porCurp[c])
	}
	sort.Slice(resultado, func(i, j int) bool {
		return resultado[i].UltimaVisita.After(resultado[j].UltimaVisita)
	})
	return resultado, nil
}
