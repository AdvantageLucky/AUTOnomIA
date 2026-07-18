package auth

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"

	"kigo-autonomia-backend/internal/domain/acceso"
	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	adminRepo  *admin.Repository
	accesoRepo *acceso.Repository
	sesionRepo *SesionRepository
	jwtSecret  string
}

func NewHandler(
	adminRepo *admin.Repository,
	accesoRepo *acceso.Repository,
	sesionRepo *SesionRepository,
	jwtSecret string,
) *Handler {
	return &Handler{
		adminRepo:  adminRepo,
		accesoRepo: accesoRepo,
		sesionRepo: sesionRepo,
		jwtSecret:  jwtSecret,
	}
}

// RegisterAdmin crea un nuevo Admin y devuelve su JWT
// Request: RegisterRequest
// Response: JWTResponse
//
// @Summary Crear admin
// @Description Registra un nuevo administrador, hasheando su password con bcrypt, y devuelve su JWT
// @Tags auth
// @Accept json
// @Produce json
// @Param admin body RegisterRequest true "Correo y password del nuevo Admin"
// @Success 201 {object} JWTResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/sign-in [post]
func (h *Handler) RegisterAdmin(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "correo y password son requeridos"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	a := &admin.Admin{
		Correo:   req.Correo,
		Password: string(hash),
	}

	if err = h.adminRepo.Create(a); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	token, err := GenerateAdminToken(a.ID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, JWTResponse{AccessToken: token})
}

// LoginAdmin da acceso al panel admin a un Admin existente
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
func (h *Handler) LoginAdmin(c *gin.Context) {
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

	token, err := GenerateAdminToken(a.ID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, JWTResponse{AccessToken: token})
}

// LoginAcceso loguea a un kiosko con el AccesoID y su ClaveKiosko, abriendo una sesion persistida
// Request: LoginAccesoRequest
// Response: SesionResponse
//
// @Summary Loguea a un kiosko
// @Description Da acceso a un kiosko a partir del ID de su Acceso y su clave, abriendo una sesion revocable
// @Tags auth
// @Accept json
// @Produce json
// @Param acceso body LoginAccesoRequest true "AccesoID y ClaveKiosko"
// @Success 201 {object} SesionResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/acceso/login [post]
func (h *Handler) LoginAcceso(c *gin.Context) {
	var req LoginAccesoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "campos incorrectos"})
		return
	}

	a, err := h.accesoRepo.FindByID(req.AccesoID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "acceso o clave invalidos"})
		return
	}

	if err = bcrypt.CompareHashAndPassword(
		[]byte(a.ClaveKiosko),
		[]byte(req.ClaveKiosko),
	); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "acceso o clave invalidos"})
		return
	}

	token, err := generateSessionToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	sesion := &SesionAcceso{AccesoID: a.ID, Token: token}
	if err := h.sesionRepo.Create(sesion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, SesionResponse{Token: token})
}

// RevocarSesionAcceso revoca todas las sesiones activas de un Acceso, ej. cuando el kiosko fue
// robado o perdido. Solo el admin propietario de ese Acceso puede revocarlo.
// Request: id uint (URL Param, acceso_id)
// Response: ok msg
//
// @Summary Revoca las sesiones de un kiosko
// @Description Revoca todas las sesiones activas del Acceso indicado, para un kiosko robado o perdido
// @Tags auth
// @Produce json
// @Param id path int true "ID del acceso"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /auth/acceso/{id}/revocar [post]
func (h *Handler) RevocarSesionAcceso(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)

	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID invalido"})
		return
	}

	if _, err := h.accesoRepo.FindByIDAndAdminID(uint(id), adminID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "acceso no encontrado"})
		return
	}

	if err := h.sesionRepo.RevokeAllByAccesoID(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "sesiones del acceso revocadas correctamente"})
}

// LoginGoogle autentica a un admin usando el id_token emitido por Google Identity Services.
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
func (h *Handler) LoginGoogle(c *gin.Context) {
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
		c.JSON(http.StatusUnauthorized, gin.H{"error": "no hay una cuenta de admin para este correo de Google"})
		return
	}

	token, err := GenerateAdminToken(a.ID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, JWTResponse{AccessToken: token})
}

type googleTokenInfo struct {
	Aud   string `json:"aud"`
	Email string `json:"email"`
	Sub   string `json:"sub"`
}

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
