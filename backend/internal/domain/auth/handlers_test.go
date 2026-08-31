package auth

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/tenant"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type mockOtpSender struct {
	sent map[string]string
}

func (m *mockOtpSender) Enviar(ctx context.Context, destino, codigo string) error {
	m.sent[destino] = codigo
	return nil
}

func setupTestAuthHandler(t *testing.T) (*Handler, *mockOtpSender, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	assert.NoError(t, err)

	err = db.AutoMigrate(&admin.Admin{}, &tenant.CentroHabitacional{}, &AdminOtpSolicitud{})
	assert.NoError(t, err)

	sender := &mockOtpSender{sent: make(map[string]string)}
	adminRepo := admin.NewRepository(db)
	tenantRepo := tenant.NewRepository(db)
	adminOtpRepo := NewAdminOtpRepository(db)
	sesionRepo := NewSesionRepository(db)
	jwtSecret := "test-secret-key-12345"

	h := NewHandler(adminRepo, nil, sesionRepo, tenantRepo, jwtSecret, adminOtpRepo, sender)
	return h, sender, db
}

func TestSignInWithOTPFlow(t *testing.T) {
	h, sender, _ := setupTestAuthHandler(t)

	r := gin.Default()
	r.POST("/auth/sign-in/solicitar-otp", h.SolicitarOtpSignInAdmin)
	r.POST("/auth/sign-in", h.RegisterAdminWithMailAndPassword)
	r.POST("/auth/login", h.LoginAdminWithMailAndPassword)

	correo := "nuevo_admin@example.com"
	password := "password123"

	// 1. Solicitar OTP para registro
	solicitarPayload, _ := json.Marshal(SolicitarOtpAdminRequest{Correo: correo})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/sign-in/solicitar-otp", bytes.NewBuffer(solicitarPayload))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	codigoEnviado := sender.sent[correo]
	assert.NotEmpty(t, codigoEnviado)

	// 2. Intentar registrarse con código incorrecto -> 401
	regPayloadBad, _ := json.Marshal(RegisterRequest{
		Correo:   correo,
		Password: password,
		Codigo:   "999999",
	})
	wBad := httptest.NewRecorder()
	reqBad, _ := http.NewRequest("POST", "/auth/sign-in", bytes.NewBuffer(regPayloadBad))
	reqBad.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wBad, reqBad)
	assert.Equal(t, http.StatusUnauthorized, wBad.Code)

	// 3. Registrarse con código correcto -> 201 Created
	regPayloadOk, _ := json.Marshal(RegisterRequest{
		Correo:   correo,
		Password: password,
		Nombre:   "Admin",
		Codigo:   codigoEnviado,
	})
	wOk := httptest.NewRecorder()
	reqOk, _ := http.NewRequest("POST", "/auth/sign-in", bytes.NewBuffer(regPayloadOk))
	reqOk.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wOk, reqOk)

	assert.Equal(t, http.StatusCreated, wOk.Code)
	var jwtResp JWTResponse
	err := json.Unmarshal(wOk.Body.Bytes(), &jwtResp)
	assert.NoError(t, err)
	assert.NotEmpty(t, jwtResp.AccessToken)

	// 4. Intentar solicitar OTP de nuevo con el mismo correo -> 409 Conflict
	wDup := httptest.NewRecorder()
	reqDup, _ := http.NewRequest("POST", "/auth/sign-in/solicitar-otp", bytes.NewBuffer(solicitarPayload))
	reqDup.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wDup, reqDup)
	assert.Equal(t, http.StatusConflict, wDup.Code)

	// 5. Iniciar sesión con correo y contraseña recién creados -> 200 OK
	loginPayload, _ := json.Marshal(LoginRequest{Correo: correo, Password: password})
	wLogin := httptest.NewRecorder()
	reqLogin, _ := http.NewRequest("POST", "/auth/login", bytes.NewBuffer(loginPayload))
	reqLogin.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wLogin, reqLogin)
	assert.Equal(t, http.StatusOK, wLogin.Code)
}

func TestForgotPasswordFlow(t *testing.T) {
	h, sender, _ := setupTestAuthHandler(t)

	r := gin.Default()
	r.POST("/auth/sign-in/solicitar-otp", h.SolicitarOtpSignInAdmin)
	r.POST("/auth/sign-in", h.RegisterAdminWithMailAndPassword)
	r.POST("/auth/login", h.LoginAdminWithMailAndPassword)
	r.POST("/auth/recuperar-password/solicitar-otp", h.SolicitarOtpRecuperarPassword)
	r.POST("/auth/recuperar-password/verificar-otp", h.RecuperarPasswordConOtp)

	correo := "admin_olvidadizo@example.com"
	passOriginal := "antiguaPassword123"
	passNueva := "nuevaPassword456"

	// 1. Registro inicial
	solicitarPayload, _ := json.Marshal(SolicitarOtpAdminRequest{Correo: correo})
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/auth/sign-in/solicitar-otp", bytes.NewBuffer(solicitarPayload))
	req.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(w, req)
	codigoReg := sender.sent[correo]

	regPayload, _ := json.Marshal(RegisterRequest{
		Correo:   correo,
		Password: passOriginal,
		Codigo:   codigoReg,
	})
	wReg := httptest.NewRecorder()
	reqReg, _ := http.NewRequest("POST", "/auth/sign-in", bytes.NewBuffer(regPayload))
	reqReg.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wReg, reqReg)
	assert.Equal(t, http.StatusCreated, wReg.Code)

	// 1.5 Solicitar OTP para un correo no registrado -> 404 Not Found
	unregisteredPayload, _ := json.Marshal(SolicitarOtpAdminRequest{Correo: "no_existe@example.com"})
	wNotFound := httptest.NewRecorder()
	reqNotFound, _ := http.NewRequest("POST", "/auth/recuperar-password/solicitar-otp", bytes.NewBuffer(unregisteredPayload))
	reqNotFound.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wNotFound, reqNotFound)
	assert.Equal(t, http.StatusNotFound, wNotFound.Code)

	// 2. Solicitar OTP de recuperación de contraseña
	wRec := httptest.NewRecorder()
	reqRec, _ := http.NewRequest("POST", "/auth/recuperar-password/solicitar-otp", bytes.NewBuffer(solicitarPayload))
	reqRec.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wRec, reqRec)
	assert.Equal(t, http.StatusOK, wRec.Code)

	codigoRec := sender.sent[correo]
	assert.NotEmpty(t, codigoRec)

	// 3. Intentar restablecer con código incorrecto -> 401
	resetBad, _ := json.Marshal(RecuperarPasswordRequest{
		Correo:      correo,
		Codigo:      "000000",
		NewPassword: passNueva,
	})
	wResetBad := httptest.NewRecorder()
	reqResetBad, _ := http.NewRequest("POST", "/auth/recuperar-password/verificar-otp", bytes.NewBuffer(resetBad))
	reqResetBad.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wResetBad, reqResetBad)
	assert.Equal(t, http.StatusUnauthorized, wResetBad.Code)

	// 4. Restablecer con código correcto -> 200 OK y devuelve JWT
	resetOk, _ := json.Marshal(RecuperarPasswordRequest{
		Correo:      correo,
		Codigo:      codigoRec,
		NewPassword: passNueva,
	})
	wResetOk := httptest.NewRecorder()
	reqResetOk, _ := http.NewRequest("POST", "/auth/recuperar-password/verificar-otp", bytes.NewBuffer(resetOk))
	reqResetOk.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wResetOk, reqResetOk)
	assert.Equal(t, http.StatusOK, wResetOk.Code)

	var jwtReset JWTResponse
	err := json.Unmarshal(wResetOk.Body.Bytes(), &jwtReset)
	assert.NoError(t, err)
	assert.NotEmpty(t, jwtReset.AccessToken)

	// 5. Intentar login con la contraseña antigua -> 401
	loginOld, _ := json.Marshal(LoginRequest{Correo: correo, Password: passOriginal})
	wLoginOld := httptest.NewRecorder()
	reqLoginOld, _ := http.NewRequest("POST", "/auth/login", bytes.NewBuffer(loginOld))
	reqLoginOld.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wLoginOld, reqLoginOld)
	assert.Equal(t, http.StatusUnauthorized, wLoginOld.Code)

	// 6. Login con la nueva contraseña -> 200 OK
	loginNew, _ := json.Marshal(LoginRequest{Correo: correo, Password: passNueva})
	wLoginNew := httptest.NewRecorder()
	reqLoginNew, _ := http.NewRequest("POST", "/auth/login", bytes.NewBuffer(loginNew))
	reqLoginNew.Header.Set("Content-Type", "application/json")
	r.ServeHTTP(wLoginNew, reqLoginNew)
	assert.Equal(t, http.StatusOK, wLoginNew.Code)
}
