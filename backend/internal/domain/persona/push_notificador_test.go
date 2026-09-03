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

func (f *fakeSender) Send(_ context.Context, deviceToken, _, _ string, _ map[string]string) error {
	f.enviados = append(f.enviados, deviceToken)
	return nil
}

type fakeMailer struct {
	enviados []string
}

func (f *fakeMailer) Enviar(_ context.Context, destino, _, _ string) error {
	f.enviados = append(f.enviados, destino)
	return nil
}

func TestPushNotificador_NotificarNuevaVisita(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	db.Exec(`CREATE TABLE admins (id INTEGER PRIMARY KEY, tenant_id INTEGER, rol TEXT, correo TEXT)`)
	db.Exec(`INSERT INTO admins (id, tenant_id, rol, correo) VALUES (1, 1, 'admin', 'admin@test.com')`)

	token := "token-abc"
	p := &Persona{Telefono: "+525512345678", DeviceToken: &token}
	repo.Create(p)
	db.Create(&residente.Membresia{PersonaID: p.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "activo"})

	pSinToken := &Persona{Telefono: "+525500000009"}
	repo.Create(pSinToken)
	db.Create(&residente.Membresia{PersonaID: pSinToken.ID, TenantID: 1, CasaDestino: "Casa 1", Status: "activo"})

	sender := &fakeSender{}
	mailer := &fakeMailer{}
	notificador := NewPushNotificador(repo, sender, mailer)

	err := notificador.NotificarNuevaVisita(context.Background(), 1, "Casa 1", visitas.Visita{Titular: "Juan"})
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(sender.enviados) != 1 || sender.enviados[0] != token {
		t.Errorf("esperaba mandar solo a %q, got %+v", token, sender.enviados)
	}
	// Todo tipo de solicitud avisa al admin por correo, aunque sí hubo push --
	// el admin quiere enterarse de cada visita sin depender del dashboard.
	if len(mailer.enviados) != 1 || mailer.enviados[0] != "admin@test.com" {
		t.Errorf("esperaba avisar al admin también cuando sí hubo push, got %+v", mailer.enviados)
	}
}

func TestPushNotificador_AvisaAlAdminSiNadieRecibeElPush(t *testing.T) {
	db := setupTestDB(t)
	repo := NewRepository(db)

	db.Exec(`CREATE TABLE admins (id INTEGER PRIMARY KEY, tenant_id INTEGER, rol TEXT, correo TEXT)`)
	db.Exec(`INSERT INTO admins (id, tenant_id, rol, correo) VALUES (1, 1, 'admin', 'admin@test.com')`)
	db.Exec(`INSERT INTO admins (id, tenant_id, rol, correo) VALUES (2, 1, 'vigilante', 'vigilante@test.com')`)

	sender := &fakeSender{}
	mailer := &fakeMailer{}
	notificador := NewPushNotificador(repo, sender, mailer)

	// Sin ninguna Membresia para "Casa 1" -- nadie recibe el push.
	err := notificador.NotificarNuevaVisita(context.Background(), 1, "Casa 1", visitas.Visita{Titular: "Juan"})
	if err != nil {
		t.Fatalf("no esperaba error, got %v", err)
	}
	if len(sender.enviados) != 0 {
		t.Errorf("no esperaba push, got %+v", sender.enviados)
	}
	if len(mailer.enviados) != 1 || mailer.enviados[0] != "admin@test.com" {
		t.Errorf("esperaba avisar solo al admin, got %+v", mailer.enviados)
	}
}
