package persona

import (
	"context"
	"testing"

	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"
)

type fakeSender struct {
	enviados []string
}

func (f *fakeSender) Send(_ context.Context, deviceToken, _, _ string) error {
	f.enviados = append(f.enviados, deviceToken)
	return nil
}

func TestPushNotificador_NotificarNuevaVisita(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	token := "token-abc"
	p := &Persona{Telefono: "+525512345678", DeviceToken: &token}
	repo.Create(p)
	db.Create(&residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "activo"})

	pSinToken := &Persona{Telefono: "+525500000009"}
	repo.Create(pSinToken)
	db.Create(&residente.Membresia{PersonaID: pSinToken.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "activo"})

	sender := &fakeSender{}
	notificador := NewPushNotificador(repo, sender)

	err := notificador.NotificarNuevaVisita(context.Background(), 1, "Casa 1", visitas.Visita{Titular: "Juan"})
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(sender.enviados) != 1 || sender.enviados[0] != token {
		t.Errorf("esperaba mandar solo a %q, got %+v", token, sender.enviados)
	}
}
