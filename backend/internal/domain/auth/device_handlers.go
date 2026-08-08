package auth

import (
	"crypto/rand"
	"net/http"
	"time"

	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

const (
	deviceCodeTTL    = 15 * time.Minute
	deviceGrantType  = "urn:ietf:params:oauth:grant-type:device_code"
	userCodeCharset  = "BCDFGHJKLMNPQRSTVWXZ"
	userCodeInterval = 5
)

type DeviceHandler struct {
	deviceRepo *DeviceRepository
	sesionRepo *SesionRepository
	kioskoRepo *kiosko.Repository
	publicURL  string
}

func NewDeviceHandler(
	deviceRepo *DeviceRepository,
	sesionRepo *SesionRepository,
	kioskoRepo *kiosko.Repository,
	publicURL string,
) *DeviceHandler {
	return &DeviceHandler{
		deviceRepo: deviceRepo,
		sesionRepo: sesionRepo,
		kioskoRepo: kioskoRepo,
		publicURL:  publicURL,
	}
}

// SolicitarCodigo genera un device_code y user_code para el flujo RFC 8628.
// POST /auth/device/authorize — sin autenticación.
func (h *DeviceHandler) SolicitarCodigo(c *gin.Context) {
	deviceCode, err := generateSessionToken() // 32 bytes hex = 64 chars
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando device_code"})
		return
	}

	userCode, err := generateUserCode()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando user_code"})
		return
	}

	da := &DeviceAuthorization{
		DeviceCode: deviceCode,
		UserCode:   userCode,
		Status:     DeviceStatusPending,
		ExpiresAt:  time.Now().Add(deviceCodeTTL),
	}
	if err := h.deviceRepo.Create(da); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando dispositivo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"device_code":      deviceCode,
		"user_code":        userCode,
		"verification_uri": h.publicURL + "/admin",
		"expires_in":       int(deviceCodeTTL.Seconds()),
		"interval":         userCodeInterval,
	})
}

// ObtenerToken hace polling del estado de la autorización. RFC 8628 §3.5.
// POST /auth/device/token — sin autenticación.
func (h *DeviceHandler) ObtenerToken(c *gin.Context) {
	var req struct {
		DeviceCode string `json:"device_code" binding:"required"`
		GrantType  string `json:"grant_type"  binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "device_code y grant_type son requeridos"})
		return
	}

	if req.GrantType != deviceGrantType {
		c.JSON(http.StatusBadRequest, gin.H{"error": "unsupported_grant_type"})
		return
	}

	da, err := h.deviceRepo.FindByDeviceCode(req.DeviceCode)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_client"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error buscando autorización"})
		return
	}

	if da.Status == DeviceStatusPending && time.Now().After(da.ExpiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "expired_token"})
		return
	}

	switch da.Status {
	case DeviceStatusPending:
		c.JSON(http.StatusPreconditionRequired, gin.H{"error": "authorization_pending"})
		return
	case DeviceStatusDenied:
		c.JSON(http.StatusBadRequest, gin.H{"error": "access_denied"})
		return
	case DeviceStatusApproved:
		token, err := generateSessionToken()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando token"})
			return
		}

		sesion := &SesionKiosko{
			KioskoID: *da.KioskoID,
			TenantID: *da.TenantID,
			Token:    token,
		}
		if err := h.sesionRepo.Create(sesion); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error creando sesión"})
			return
		}

		var claveKiosko string
		if da.ClaveKioskoPlain != nil {
			claveKiosko = *da.ClaveKioskoPlain
			_ = h.deviceRepo.LimpiarClave(da.ID)
		}
		_ = h.deviceRepo.SoftDelete(da.ID)

		c.JSON(http.StatusOK, gin.H{
			"token":        token,
			"kiosko_id":   *da.KioskoID,
			"clave_kiosko": claveKiosko,
		})
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid_client"})
	}
}

// ListarPendientes devuelve las autorizaciones pendientes del tenant del admin autenticado.
// GET /device/pending — RequireAdmin.
func (h *DeviceHandler) ListarPendientes(c *gin.Context) {
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	list, err := h.deviceRepo.FindPendingByTenant(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error listando dispositivos"})
		return
	}

	type item struct {
		UserCode  string    `json:"user_code"`
		CreatedAt time.Time `json:"created_at"`
		ExpiresAt time.Time `json:"expires_at"`
	}
	result := make([]item, 0, len(list))
	for _, da := range list {
		result = append(result, item{
			UserCode:  da.UserCode,
			CreatedAt: da.CreatedAt,
			ExpiresAt: da.ExpiresAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"dispositivos": result})
}

// AprobarDispositivo aprueba un user_code y lo asocia a un kiosko del tenant del admin.
// POST /device/:user_code/aprobar — RequireAdmin.
func (h *DeviceHandler) AprobarDispositivo(c *gin.Context) {
	adminID := c.MustGet(ctxkeys.AdminID).(uint)
	tenantID := c.MustGet(ctxkeys.TenantID).(uint)
	userCode := c.Param("user_code")

	var req struct {
		KioskoID    uint   `json:"kiosko_id"    binding:"required"`
		ClaveKiosko string `json:"clave_kiosko" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "kiosko_id y clave_kiosko son requeridos"})
		return
	}

	// Verificar que el kiosko pertenezca al admin y al tenant
	k, err := h.kioskoRepo.FindByIDAndAdminID(req.KioskoID, adminID)
	if err != nil || k.TenantID != tenantID {
		c.JSON(http.StatusNotFound, gin.H{"error": "kiosko no encontrado"})
		return
	}

	if err := h.deviceRepo.Aprobar(userCode, req.KioskoID, tenantID, req.ClaveKiosko); err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "código no encontrado o ya procesado"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error aprobando dispositivo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "dispositivo aprobado"})
}

// ValidarCodigo verifica si un user_code existe y está pendiente de aprobación.
// GET /device/validar?user_code=XXXX-XXXX — RequireAdmin.
func (h *DeviceHandler) ValidarCodigo(c *gin.Context) {
	userCode := c.Query("user_code")
	if userCode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_code es requerido"})
		return
	}

	da, err := h.deviceRepo.FindByUserCode(userCode)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "código no encontrado o ya procesado"})
		return
	}

	if time.Now().After(da.ExpiresAt) {
		c.JSON(http.StatusGone, gin.H{"error": "expired_token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"valid": true, "user_code": da.UserCode})
}

// generateUserCode genera un código de 8 caracteres con guión en el centro (XXXX-XXXX)
// usando el charset sin vocales para evitar palabras accidentales.
func generateUserCode() (string, error) {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	charset := []byte(userCodeCharset)
	code := make([]byte, 9) // 4 + guion + 4
	for i := 0; i < 4; i++ {
		code[i] = charset[int(b[i])%len(charset)]
	}
	code[4] = '-'
	for i := 0; i < 4; i++ {
		code[5+i] = charset[int(b[4+i])%len(charset)]
	}
	return string(code), nil
}
