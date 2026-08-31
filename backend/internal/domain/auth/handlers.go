/*
Package auth

Handlers relacionados con el dominio auth
Hace uso del repository relacionado a auth, admin y kiosko

Hay 3 tipos de autorizacion:
1. Autorizacion a Administradores: desbloquean panel de bitacora
Pueden registrarse/loguearse con correo/contraseña o google services

2. Autorizacion a Kioskos: desbloquean operaciones en endpoints orientados a kiosko
Pueden registrarse con codigo qr que redirigue a registro de kioskos (se necesita cuenta
de admin logueada) o con codigo numerico

3. Autorizacion a residentes: desbloquean la app orientada a residentes. Se auto-registran
con el codigo publico de su instalacion (ver internal/domain/residente y ADR 0020) y quedan
pendientes de aprobacion del admin; el login usa casa_destino + PIN

Documentado con swag
*/
package auth

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/domain/tenant"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Handler struct {
	adminRepo    *admin.Repository
	kioskoRepo   *kiosko.Repository
	sesionRepo   *SesionRepository
	tenantRepo   tenant.Repository
	jwtSecret    string
	adminOtpRepo *AdminOtpRepository
	emailSender  OtpSender
}

func NewHandler(
	adminRepo *admin.Repository,
	kioskoRepo *kiosko.Repository,
	sesionRepo *SesionRepository,
	tenantRepo tenant.Repository,
	jwtSecret string,
	adminOtpRepo *AdminOtpRepository,
	emailSender OtpSender,
) *Handler {
	return &Handler{
		adminRepo:    adminRepo,
		kioskoRepo:   kioskoRepo,
		sesionRepo:   sesionRepo,
		tenantRepo:   tenantRepo,
		jwtSecret:    jwtSecret,
		adminOtpRepo: adminOtpRepo,
		emailSender:  emailSender,
	}
}

// func helper para verificar un token credencial emitido por google services sea valido (para logearse/registrarse)
func verifyGoogleToken(credential string) (*googleTokenInfo, error) {
	url := fmt.Sprintf("https://oauth2.googleapis.com/tokeninfo?id_token=%s", credential)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("google tokeninfo devolvio %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var info googleTokenInfo
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, err
	}

	return &info, nil
}

// RegisterAdminWithMailAndPassword crea un nuevo Admin y devuelve su JWT
// Request: RegisterRequest
// Response: JWTResponse
//
// @Summary Crear admin
// @Description Registra un nuevo administrador previa verificación de código OTP por correo, hasheando su password con bcrypt, y devuelve su JWT
// @Tags auth
// @Accept json
// @Produce json
// @Param admin body RegisterRequest true "Correo, password, datos y código OTP del nuevo Admin"
// @Success 201 {object} JWTResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 409 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/sign-in [post]
func (h *Handler) RegisterAdminWithMailAndPassword(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "correo y password son requeridos"})
		return
	}

	rol := "admin"
	var tenantID uint
	if req.Rol == "vigilante" {
		tokenHeader := c.GetHeader("Authorization")
		if after, ok := strings.CutPrefix(tokenHeader, "Bearer "); ok {
			_, rolSolicitante, tenantSolicitante, e := ParseAdminToken(after, h.jwtSecret)
			if e == nil && rolSolicitante == "admin" {
				rol = "vigilante"
				tenantID = tenantSolicitante // el vigilante se une al tenant del admin que lo crea
			}
		}
	}

	// Si es auto-registro de admin, se exige y valida el código OTP de verificación de correo
	if rol == "admin" {
		if req.Codigo == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "código de verificación es requerido"})
			return
		}

		solicitud, err := h.adminOtpRepo.FindActivaPorCorreo(req.Correo)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
			return
		}

		if subtle.ConstantTimeCompare([]byte(solicitud.Codigo), []byte(req.Codigo)) != 1 {
			if intentos, incErr := h.adminOtpRepo.IncrementarIntentos(solicitud.ID); incErr == nil && intentos >= 5 {
				_ = h.adminOtpRepo.InvalidarPorCorreo(req.Correo)
			}
			c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
			return
		}

		_ = h.adminOtpRepo.InvalidarPorCorreo(req.Correo)
	}

	if _, err := h.adminRepo.FindByCorreo(req.Correo); err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "ya existe una cuenta registrada con este correo"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if rol == "admin" {
		// Cada admin nuevo es dueño de su propia instalación (tenant).
		nuevoTenant := &tenant.CentroHabitacional{}
		if err := h.tenantRepo.Create(nuevoTenant); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando instalación"})
			return
		}
		tenantID = nuevoTenant.ID
	}

	a := &admin.Admin{
		TenantID:        tenantID,
		Correo:          req.Correo,
		Password:        string(hash),
		Rol:             rol,
		Nombre:          req.Nombre,
		ApellidoPaterno: req.ApellidoPaterno,
	}

	if err = h.adminRepo.Create(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	token, err := GenerateAdminToken(a.ID, a.Rol, a.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, JWTResponse{AccessToken: token})
}

// LoginAdminWithMailAndPassword da acceso al panel admin a un Admin con su correo/contraseña
// Request: LoginRequest
// Response: JWTResponse
//
// @Summary Loguea a un admin
// @Description Da acceso a un admin a partir de su correo y contraseña, devolviendo un JWT
// @Tags auth
// @Accept json
// @Produce json
// @Param admin body LoginRequest true "Correo y password del Admin"
// @Success 200 {object} JWTResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /auth/login [post]
func (h *Handler) LoginAdminWithMailAndPassword(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	a, err := h.adminRepo.FindByCorreo(req.Correo)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "correo invalido"})
		return
	}

	if err = bcrypt.CompareHashAndPassword([]byte(a.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "contraseña invalida"})
		return
	}

	token, err := GenerateAdminToken(a.ID, a.Rol, a.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, JWTResponse{AccessToken: token})
}

// SolicitarOtpSignInAdmin genera y envía un código OTP al correo del usuario
// para verificar la dirección de correo antes de completar el registro (Sign-in).
// Válido por 5 minutos.
func (h *Handler) SolicitarOtpSignInAdmin(c *gin.Context) {
	var req SolicitarOtpAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if _, err := h.adminRepo.FindByCorreo(req.Correo); err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "ya existe una cuenta registrada con este correo"})
		return
	}

	if _, err := h.adminOtpRepo.FindActivaPorCorreo(req.Correo); err == nil {
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "ya tienes un código activo, espera a que expire"})
		return
	}

	codigo, err := generarCodigoOtpAdmin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	solicitud := &AdminOtpSolicitud{
		Correo:   req.Correo,
		Codigo:   codigo,
		ExpiraEn: time.Now().Add(5 * time.Minute),
	}
	if err := h.adminOtpRepo.Create(solicitud); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := h.emailSender.Enviar(c.Request.Context(), req.Correo, codigo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo enviar el código"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "código de verificación enviado"})
}

// SolicitarOtpRecuperarPassword genera y manda por correo un código para
// restablecer la contraseña si el admin la olvidó.
func (h *Handler) SolicitarOtpRecuperarPassword(c *gin.Context) {
	var req SolicitarOtpAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if _, err := h.adminRepo.FindByCorreo(req.Correo); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no existe ninguna cuenta registrada con este correo"})
		return
	}

	if _, err := h.adminOtpRepo.FindActivaPorCorreo(req.Correo); err == nil {
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "ya tienes un código activo, espera a que expire"})
		return
	}

	codigo, err := generarCodigoOtpAdmin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	solicitud := &AdminOtpSolicitud{
		Correo:   req.Correo,
		Codigo:   codigo,
		ExpiraEn: time.Now().Add(5 * time.Minute),
	}
	if err := h.adminOtpRepo.Create(solicitud); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := h.emailSender.Enviar(c.Request.Context(), req.Correo, codigo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo enviar el código"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "si el correo existe, se envió un código"})
}

// RecuperarPasswordConOtp confirma el código OTP y actualiza la contraseña del Admin.
func (h *Handler) RecuperarPasswordConOtp(c *gin.Context) {
	var req RecuperarPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	solicitud, err := h.adminOtpRepo.FindActivaPorCorreo(req.Correo)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
		return
	}
	if subtle.ConstantTimeCompare([]byte(solicitud.Codigo), []byte(req.Codigo)) != 1 {
		if intentos, incErr := h.adminOtpRepo.IncrementarIntentos(solicitud.ID); incErr == nil && intentos >= 5 {
			_ = h.adminOtpRepo.InvalidarPorCorreo(req.Correo)
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
		return
	}

	a, err := h.adminRepo.FindByCorreo(req.Correo)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "usuario no encontrado"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	a.Password = string(hash)
	if err := h.adminRepo.Update(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error actualizando contraseña"})
		return
	}

	_ = h.adminOtpRepo.InvalidarPorCorreo(req.Correo)

	token, err := GenerateAdminToken(a.ID, a.Rol, a.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, JWTResponse{AccessToken: token})
}

// LoginWithGoogle autentica a un admin usando el id_token emitido por Google Identity Services.
// El frontend manda el credential del popup de Google; el backend lo verifica con la API de
// tokeninfo de Google y, si el email está registrado como admin, devuelve un JWT propio.
//
// @Summary Login con Google (dashboard)
// @Tags auth
// @Accept json
// @Produce json
// @Param body body GoogleLoginRequest true "credential (id_token) de Google"
// @Success 200 {object} JWTResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Router /auth/google [post]
func (h *Handler) LoginWithGoogle(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "credential requerido"})
		return
	}

	googleClientID := os.Getenv("GOOGLE_CLIENT_ID")
	if googleClientID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Google login no configurado"})
		return
	}

	tokenInfo, err := verifyGoogleToken(req.Credential)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token de Google invalido"})
		return
	}

	if tokenInfo.Aud != googleClientID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token no corresponde a esta aplicacion"})
		return
	}

	a, err := h.adminRepo.FindByCorreo(tokenInfo.Email)
	if err != nil {
		c.JSON(
			http.StatusUnauthorized,
			gin.H{"error": "no hay una cuenta de admin para este correo de Google"},
		)
		return
	}

	token, err := GenerateAdminToken(a.ID, a.Rol, a.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, JWTResponse{AccessToken: token})
}

// RegisterWithGoogle registra un nuevo Admin usando el id_token de Google Identity Services.
// Si el correo ya tiene una cuenta, devuelve 409.
// El Admin creado no tiene password utilizable: solo puede autenticarse via Google.
//
// @Summary Registrar admin con Google
// @Tags auth
// @Accept json
// @Produce json
// @Param body body GoogleLoginRequest true "credential (id_token) de Google"
// @Success 201 {object} JWTResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 409 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/google/sign-in [post]
func (h *Handler) RegisterWithGoogle(c *gin.Context) {
	var req GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "credential requerido"})
		return
	}

	googleClientID := os.Getenv("GOOGLE_CLIENT_ID")
	if googleClientID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Google login no configurado"})
		return
	}

	tokenInfo, err := verifyGoogleToken(req.Credential)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token de Google invalido"})
		return
	}

	if tokenInfo.Aud != googleClientID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token no corresponde a esta aplicacion"})
		return
	}

	if _, err = h.adminRepo.FindByCorreo(tokenInfo.Email); err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "ya existe una cuenta con este correo"})
		return
	} else if err != gorm.ErrRecordNotFound {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	randBytes := make([]byte, 32)
	if _, err = rand.Read(randBytes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(hex.EncodeToString(randBytes)), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	nuevoTenant := &tenant.CentroHabitacional{}
	if err = h.tenantRepo.Create(nuevoTenant); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando instalación"})
		return
	}

	a := &admin.Admin{
		TenantID: nuevoTenant.ID,
		Correo:   tokenInfo.Email,
		Password: string(hash),
	}
	if err = h.adminRepo.Create(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	token, err := GenerateAdminToken(a.ID, a.Rol, a.TenantID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, JWTResponse{AccessToken: token})
}

// LoginKiosko loguea a un kiosko con el KioskoID y su ClaveKiosko, abriendo una sesion persistida
// Request: LoginKioskoRequest
// Response: SesionResponse
//
// @Summary Loguea a un kiosko
// @Description Da acceso a un kiosko a partir del ID del Kiosko y su clave, abriendo una sesion revocable
// @Tags auth
// @Accept json
// @Produce json
// @Param kiosko body LoginKioskoRequest true "KioskoID y ClaveKiosko"
// @Success 201 {object} SesionResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/kiosko/login [post]
func (h *Handler) LoginKiosko(c *gin.Context) {
	var req LoginKioskoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	a, err := h.kioskoRepo.FindByID(req.KioskoID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "kiosko o clave invalidos"})
		return
	}

	if err = bcrypt.CompareHashAndPassword([]byte(a.ClaveKiosko), []byte(req.ClaveKiosko)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "kiosko o clave invalidos"})
		return
	}

	token, err := generateSessionToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	sesion := &SesionKiosko{
		KioskoID: a.ID,
		Token:    token,
		TenantID: a.TenantID,
	}
	if err := h.sesionRepo.Create(sesion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, SesionResponse{Token: token})
}

// RevocarSesionKiosko revoca todas las sesiones activas de un Kiosko, ej. cuando el kiosko fue
// robado o perdido. Solo el admin propietario de ese Kiosko puede revocarlo.
// Request: id uint (URL Param, kiosko_id)
// Response: ok msg
//
// @Summary Revoca las sesiones de un kiosko
// @Description Revoca todas las sesiones activas del Kiosko indicado, para un kiosko robado o perdido
// @Tags auth
// @Produce json
// @Param id path int true "ID del kiosko"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/kiosko/{id}/revocar [post]
func (h *Handler) RevocarSesionKiosko(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if _, err := h.kioskoRepo.FindByIDAndAdminID(uint(id), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	if err := h.sesionRepo.RevokeAllByKioskoID(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "sesiones del kiosko revocadas correctamente"})
}
