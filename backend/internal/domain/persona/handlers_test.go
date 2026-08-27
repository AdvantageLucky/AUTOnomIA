package persona

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"kigo-autonomia-backend/internal/platform/ctxkeys"
)

func TestRegistrarDeviceToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	db := setupTestDB(t)
	repo := NewRepository(db)
	p := &Persona{Telefono: "+525512345678"}
	repo.Create(p)

	h := NewHandler(repo, nil, nil, nil, "", "", nil, nil, nil, nil, nil, "")

	router := gin.New()
	router.POST("/personas/me/device-token", func(c *gin.Context) {
		c.Set(ctxkeys.PersonaID, p.ID)
		c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), ctxkeys.PersonaID, p.ID))
		h.RegistrarDeviceToken(c)
	})

	body, _ := json.Marshal(map[string]string{"device_token": "token-xyz"})
	req := httptest.NewRequest(http.MethodPost, "/personas/me/device-token", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("esperaba 200, got %d: %s", w.Code, w.Body.String())
	}

	found, _ := repo.FindByID(p.ID)
	if found.DeviceToken == nil || *found.DeviceToken != "token-xyz" {
		t.Errorf("esperaba device_token guardado, got %+v", found.DeviceToken)
	}
}
