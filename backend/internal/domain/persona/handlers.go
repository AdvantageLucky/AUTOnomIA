package persona

import (
	"crypto/subtle"
	"net/http"
	"time"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	repo           *Repository
	otpRepo        *OtpRepository
	sender         OtpSender
	jwtSecret      string
	qrMasterSecret string
}

func NewHandler(repo *Repository, otpRepo *OtpRepository, sender OtpSender, jwtSecret, qrMasterSecret string) *Handler {
	return &Handler{
		repo:           repo,
		otpRepo:        otpRepo,
		sender:         sender,
		jwtSecret:      jwtSecret,
		qrMasterSecret: qrMasterSecret,
	}
}

// SolicitarOTP genera y "manda" (ver OtpSender) un código de verificación
// para un teléfono. Válido 5 minutos.
func (h *Handler) SolicitarOTP(c *gin.Context) {
	var req SolicitarOtpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	codigo, err := generarCodigoOtp()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	solicitud := &OtpSolicitud{
		Telefono: req.Telefono,
		Codigo:   codigo,
		ExpiraEn: time.Now().Add(5 * time.Minute),
	}
	if err := h.otpRepo.Create(solicitud); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := h.sender.Enviar(c.Request.Context(), req.Telefono, codigo); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo enviar el código"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "código enviado"})
}

// VerificarOTP confirma el código, crea (o reusa, si el teléfono ya tenía
// Persona) la Persona, y regresa su sesión de app.
func (h *Handler) VerificarOTP(c *gin.Context) {
	var req VerificarOtpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	solicitud, err := h.otpRepo.FindActivaPorTelefono(req.Telefono)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
		return
	}
	if subtle.ConstantTimeCompare([]byte(solicitud.Codigo), []byte(req.Codigo)) != 1 {
		// Corta por fuerza bruta: tras 5 intentos fallidos, se invalida el
		// código y hay que pedir uno nuevo — no se puede seguir adivinando
		// indefinidamente dentro de la ventana de 5 minutos.
		if intentos, incErr := h.otpRepo.IncrementarIntentos(solicitud.ID); incErr == nil && intentos >= 5 {
			_ = h.otpRepo.InvalidarPorTelefono(req.Telefono)
		}
		c.JSON(http.StatusUnauthorized, gin.H{"error": "código inválido o vencido"})
		return
	}

	ahora := time.Now()
	p, err := h.repo.FindByTelefono(req.Telefono)
	if err != nil {
		p = &Persona{Telefono: req.Telefono, TelefonoVerificadoAt: &ahora}
		if err := h.repo.Create(p); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	if err := h.otpRepo.InvalidarPorTelefono(req.Telefono); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	token, err := auth.GeneratePersonaToken(p.ID, h.jwtSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, auth.JWTResponse{AccessToken: token})
}

// GetQR devuelve el persona_id y su firma — es lo que la app codifica en el
// QR personal, que el kiosko puede verificar offline con la misma llave
// maestra.
func (h *Handler) GetQR(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)
	firma := FirmarPersonaID(personaID, h.qrMasterSecret)
	c.JSON(http.StatusOK, QrResponse{PersonaID: personaID, Firma: firma})
}
