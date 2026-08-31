package admin

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestAdminDB(t *testing.T) (*Handler, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)

	err = db.AutoMigrate(&Admin{})
	assert.NoError(t, err)

	repo := NewRepository(db)
	h := NewHandler(repo)
	return h, db
}

func TestPatchAdminPreservesTenantAndUpdatesFields(t *testing.T) {
	h, db := setupTestAdminDB(t)

	hash, _ := bcrypt.GenerateFromPassword([]byte("oldPassword123"), bcrypt.DefaultCost)
	adminInit := Admin{
		TenantID:        42,
		Rol:             "admin",
		Nombre:          "Carlos",
		ApellidoPaterno: "Pérez",
		ApellidoMaterno: "Gómez",
		Correo:          "carlos@example.com",
		Password:        string(hash),
	}
	err := db.Create(&adminInit).Error
	assert.NoError(t, err)

	r := gin.Default()
	r.PATCH("/admins/:id", func(c *gin.Context) {
		c.Set(ctxkeys.AdminID, adminInit.ID)
		c.Set(ctxkeys.TenantID, adminInit.TenantID)
		h.PatchAdmin(c)
	})

	updateBody, _ := json.Marshal(AdminRequest{
		Nombre:          "Carlos Eduardo",
		ApellidoPaterno: "Pérez",
		ApellidoMaterno: "Gómez",
		Correo:          "carlos.nuevo@example.com",
		Password:        "nuevaPassword456",
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PATCH", "/admins/1", bytes.NewBuffer(updateBody))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var resp AdminResponse
	err = json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, "Carlos Eduardo", resp.Nombre)
	assert.Equal(t, "carlos.nuevo@example.com", resp.Correo)

	// Verificar en DB que TenantID y Rol se preservaron intactos
	var updated Admin
	err = db.First(&updated, adminInit.ID).Error
	assert.NoError(t, err)
	assert.Equal(t, uint(42), updated.TenantID)
	assert.Equal(t, "admin", updated.Rol)
	assert.Equal(t, "Carlos Eduardo", updated.Nombre)
	assert.Equal(t, "carlos.nuevo@example.com", updated.Correo)

	// Verificar que el hash de la contraseña se actualizó correctamente
	err = bcrypt.CompareHashAndPassword([]byte(updated.Password), []byte("nuevaPassword456"))
	assert.NoError(t, err)
}

func TestPatchAdminWithoutPasswordKeepsExistingPassword(t *testing.T) {
	h, db := setupTestAdminDB(t)

	hash, _ := bcrypt.GenerateFromPassword([]byte("originalPassword123"), bcrypt.DefaultCost)
	adminInit := Admin{
		TenantID:        42,
		Rol:             "admin",
		Nombre:          "Laura",
		ApellidoPaterno: "Hernández",
		ApellidoMaterno: "Ruiz",
		Correo:          "laura@example.com",
		Password:        string(hash),
	}
	err := db.Create(&adminInit).Error
	assert.NoError(t, err)

	r := gin.Default()
	r.PATCH("/admins/:id", func(c *gin.Context) {
		c.Set(ctxkeys.AdminID, adminInit.ID)
		c.Set(ctxkeys.TenantID, adminInit.TenantID)
		h.PatchAdmin(c)
	})

	updateBody, _ := json.Marshal(map[string]interface{}{
		"nombre":           "Laura Elena",
		"apellido_paterno": "Hernández",
		"apellido_materno": "Ruiz",
		"correo":           "laura.elena@example.com",
	})

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PATCH", "/admins/1", bytes.NewBuffer(updateBody))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var resp AdminResponse
	err = json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NoError(t, err)
	assert.Equal(t, "Laura Elena", resp.Nombre)

	var updated Admin
	err = db.First(&updated, adminInit.ID).Error
	assert.NoError(t, err)
	assert.Equal(t, "Laura Elena", updated.Nombre)

	// La contraseña no cambió
	err = bcrypt.CompareHashAndPassword([]byte(updated.Password), []byte("originalPassword123"))
	assert.NoError(t, err)
}
