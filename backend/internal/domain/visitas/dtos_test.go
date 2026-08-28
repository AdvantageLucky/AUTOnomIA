package visitas

import (
	"encoding/json"
	"testing"
)

func TestToVisitaListItemResponse_WalkInConAnalisis(t *testing.T) {
	scoreJSON, _ := json.Marshal(ScoreIA{VecesVisitado: 2, Confiable: true})
	v := Visita{
		Titular: "Ana", TipoVisitante: TipoSinInvitacion,
		ResumenIA: "Visitante frecuente, sin incidencias.",
		ScoreIA:   scoreJSON,
	}
	v.ID = 1

	item := toVisitaListItemResponse(v)

	if item.ResumenIA == nil || *item.ResumenIA != "Visitante frecuente, sin incidencias." {
		t.Errorf("esperaba ResumenIA presente, got %v", item.ResumenIA)
	}
	if item.ScoreIA == nil || !item.ScoreIA.Confiable {
		t.Errorf("esperaba ScoreIA.Confiable=true, got %+v", item.ScoreIA)
	}
	if item.Estadisticas != nil {
		t.Errorf("esperaba Estadisticas nil en una visita walk-in, got %+v", item.Estadisticas)
	}
}

func TestToVisitaListItemResponse_SinAnalisisTodavia(t *testing.T) {
	v := Visita{Titular: "Ana", TipoVisitante: TipoSinInvitacion, Estado: EstadoPendiente}
	v.ID = 1

	item := toVisitaListItemResponse(v)

	if item.ResumenIA != nil || item.ScoreIA != nil {
		t.Errorf("esperaba ResumenIA/ScoreIA nil mientras el analisis no termina, got %v / %v", item.ResumenIA, item.ScoreIA)
	}
}

func TestToVisitaListItemResponse_RutaAutomaticaSinAnalisis(t *testing.T) {
	personaID := uint(5)
	v := Visita{Titular: "Beto", TipoVisitante: TipoResidente, PersonaID: &personaID}
	v.ID = 1

	item := toVisitaListItemResponse(v)

	if item.ResumenIA != nil || item.ScoreIA != nil {
		t.Errorf("esperaba ResumenIA/ScoreIA nil en una ruta automatica, got %v / %v", item.ResumenIA, item.ScoreIA)
	}
}
