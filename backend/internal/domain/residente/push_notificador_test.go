package residente

import "testing"

func TestConDeviceToken_FiltraResidentesSinToken(t *testing.T) {
	token := "token-abc"
	residentes := []Residente{
		{DeviceToken: &token},
		{DeviceToken: nil},
		{DeviceToken: func() *string { s := ""; return &s }()},
	}

	con := conDeviceToken(residentes)

	if len(con) != 1 {
		t.Fatalf("esperaba 1 residente con token, got %d", len(con))
	}
	if con[0].DeviceToken == nil || *con[0].DeviceToken != token {
		t.Errorf("esperaba el residente con token %q, got %+v", token, con[0])
	}
}

func TestConDeviceToken_ListaVacia(t *testing.T) {
	con := conDeviceToken(nil)
	if len(con) != 0 {
		t.Errorf("esperaba lista vacía, got %d", len(con))
	}
}
