package persona

import (
	"crypto/subtle"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/tenant"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Handler struct {
	repo           *Repository
	otpRepo        *OtpRepository
	sender         OtpSender
	jwtSecret      string
	qrMasterSecret string
	membresiaRepo  *residente.MembresiaRepository
	tenantRepo     tenant.Repository
	invitacionRepo *invitaciones.Repository
	visitaRepo     *visitas.Repository
}

func NewHandler(
	repo *Repository,
	otpRepo *OtpRepository,
	sender OtpSender,
	jwtSecret, qrMasterSecret string,
	membresiaRepo *residente.MembresiaRepository,
	tenantRepo tenant.Repository,
	invitacionRepo *invitaciones.Repository,
	visitaRepo *visitas.Repository,
) *Handler {
	return &Handler{
		repo:           repo,
		otpRepo:        otpRepo,
		sender:         sender,
		jwtSecret:      jwtSecret,
		qrMasterSecret: qrMasterSecret,
		membresiaRepo:  membresiaRepo,
		tenantRepo:     tenantRepo,
		invitacionRepo: invitacionRepo,
		visitaRepo:     visitaRepo,
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

	if _, err := h.otpRepo.FindActivaPorTelefono(req.Telefono); err == nil {
		// Ya hay un código activo para este teléfono — no se genera uno
		// nuevo: permitir "resetear" el contador de intentos pidiendo otro
		// código es exactamente el hueco de fuerza bruta que el límite de
		// intentos debía cerrar.
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "ya tienes un código activo, espera a que expire"})
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
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	esRegistro := errors.Is(err, gorm.ErrRecordNotFound) || (p != nil && p.TelefonoVerificadoAt == nil)
	if esRegistro {
		// Nombre/apellidos ya NO son requeridos aquí — la app los pide en un
		// paso posterior vía PATCH /personas/me (que sí los exige). Exigirlos
		// en esta misma llamada obligaba a la app a mandar el perfil junto
		// con el código de un tirón, algo que el flujo de onboarding de la
		// app (teléfono → OTP → perfil → unirse a centro) nunca hace.
		nombre := strings.TrimSpace(req.Nombre)
		apellidoPaterno := strings.TrimSpace(req.ApellidoPaterno)
		if errors.Is(err, gorm.ErrRecordNotFound) {
			p = &Persona{
				Telefono:             req.Telefono,
				TelefonoVerificadoAt: &ahora,
				Nombre:               nombre,
				ApellidoPaterno:      apellidoPaterno,
				ApellidoMaterno:      strings.TrimSpace(req.ApellidoMaterno),
				Embedding:            residente.FloatArray(req.Embedding),
			}
			if err := h.repo.Create(p); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
		} else {
			p.TelefonoVerificadoAt = &ahora
			if nombre != "" {
				p.Nombre = nombre
			}
			if apellidoPaterno != "" {
				p.ApellidoPaterno = apellidoPaterno
			}
			if am := strings.TrimSpace(req.ApellidoMaterno); am != "" {
				p.ApellidoMaterno = am
			}
			if len(req.Embedding) > 0 {
				p.Embedding = residente.FloatArray(req.Embedding)
			}
			if err := h.repo.Update(p); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
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

// UnirseCentro crea una Membresia pendiente de una Persona en un centro,
// identificado por su código público — mismo patrón que el auto-registro
// de Residente hoy: la Membresia nace en pendiente y el admin la aprueba.
func (h *Handler) UnirseCentro(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	var req UnirseCentroRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	t, err := h.tenantRepo.FindByCodigo(strings.TrimSpace(req.CodigoCentro))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error procesando pin"})
		return
	}

	existente, err := h.membresiaRepo.FindByPersonaAndTenant(personaID, t.ID)
	if err == nil {
		if existente.Status != residente.ResidenteStatusRechazado {
			c.JSON(http.StatusConflict, gin.H{"error": "ya tienes una membresía en este centro"})
			return
		}
		existente.CasaDestino = strings.TrimSpace(req.CasaDestino)
		existente.Pin = string(hash)
		existente.Status = residente.ResidenteStatusPendiente
		if err := h.membresiaRepo.Update(existente); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, MembresiaResponse{
			ID:          existente.ID,
			TenantID:    existente.TenantID,
			CasaDestino: existente.CasaDestino,
			Rol:         existente.Rol,
			Status:      existente.Status,
		})
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	m := &residente.Membresia{
		PersonaID:   personaID,
		TenantID:    t.ID,
		CasaDestino: strings.TrimSpace(req.CasaDestino),
		Pin:         string(hash),
		Rol:         residente.MembresiaRolTitular,
		Status:      residente.ResidenteStatusPendiente,
	}
	if err := h.membresiaRepo.Create(m); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, MembresiaResponse{
		ID:          m.ID,
		TenantID:    m.TenantID,
		CasaDestino: m.CasaDestino,
		Rol:         m.Rol,
		Status:      m.Status,
	})
}

// CrearInvitacion crea una invitación anclada a Persona: quien invita debe
// tener una Membresia activa en el tenant, y a quien se invita se
// identifica por teléfono (se le crea una Persona "en blanco" si nunca ha
// usado Kigo).
func (h *Handler) CrearInvitacion(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	var req CrearInvitacionPersonaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	m, err := h.membresiaRepo.FindByPersonaAndTenant(personaID, req.TenantID)
	if err != nil || m.Status != residente.ResidenteStatusActivo {
		c.JSON(http.StatusForbidden, gin.H{"error": "no tienes una membresía activa en ese centro"})
		return
	}

	invitado, err := h.repo.FindOrCreateByTelefono(strings.TrimSpace(req.TelefonoInvitado))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	token, err := invitaciones.GenerarToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error generando token"})
		return
	}

	titular := strings.TrimSpace(req.NombreInvitado)
	if titular == "" {
		titular = invitado.Nombre
	}
	if titular == "" {
		titular = invitado.Telefono
	}

	inv := &invitaciones.Invitacion{
		Token:                       token,
		TenantID:                    req.TenantID,
		Tipo:                        req.Tipo,
		Titular:                     titular,
		DestinoID:                   req.DestinoID,
		PersonaInvitadaID:           &invitado.ID,
		PersonaCreadoraID:           &personaID,
		PermiteReconocimientoFacial: req.PermiteReconocimientoFacial,
		MaxUsos:                     req.MaxUsos,
		ExpiresAt:                   req.ExpiresAt,
	}
	if err := h.invitacionRepo.Create(inv); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, invitaciones.ToInvitacionResponse(inv, false))
}

// ListarInvitaciones lista las invitaciones creadas por la Persona autenticada.
func (h *Handler) ListarInvitaciones(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	list, err := h.invitacionRepo.FindByPersonaCreadora(personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := make([]invitaciones.InvitacionResponse, len(list))
	for i, inv := range list {
		resp[i] = invitaciones.ToInvitacionResponse(&inv, false)
	}
	c.JSON(http.StatusOK, resp)
}

// VerificarQR resuelve un QR personal escaneado por el kiosko: verifica la
// firma HMAC y, en la misma respuesta, si la Persona tiene membresía o
// invitación activa en el tenant del kiosko. Si viene un embedding, se
// enrola de una vez (ver spec §11) — no crea ninguna Visita, eso lo decide
// el flujo del kiosko con esta resolución en la mano.
func (h *Handler) VerificarQR(c *gin.Context) {
	var req VerificarQRRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if !VerificarFirma(req.PersonaID, req.Firma, h.qrMasterSecret) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "firma inválida"})
		return
	}

	p, err := h.repo.FindByID(req.PersonaID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "persona no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tenantID := c.MustGet(ctxkeys.TenantID).(uint)

	var membresia *residente.Membresia
	if m, err := h.membresiaRepo.FindByPersonaAndTenant(req.PersonaID, tenantID); err == nil {
		membresia = m
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var invitacion *invitaciones.Invitacion
	if inv, err := h.invitacionRepo.FindActivaByPersonaInvitadaAndTenant(req.PersonaID, tenantID); err == nil {
		invitacion = inv
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resolucion := ResolverEstadoQR(p, membresia, invitacion)

	puedeEnrolar := resolucion.Estado == EstadoQRMiembro ||
		(resolucion.Estado == EstadoQRInvitado && invitacion != nil && invitacion.PermiteReconocimientoFacial)

	if len(req.Embedding) > 0 && p.Embedding == nil && puedeEnrolar {
		if err := h.repo.UpdateEmbedding(req.PersonaID, req.Embedding); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if membresia != nil && membresia.Status == residente.ResidenteStatusActivo {
			if err := h.membresiaRepo.UpdatePermiteReconocimientoFacial(membresia.ID, true); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			resolucion.PermiteReconocimientoFacial = true
		}
	}

	c.JSON(http.StatusOK, VerificarQRResponse{
		Estado:                      resolucion.Estado,
		Nombre:                      resolucion.Nombre,
		CasaDestino:                 resolucion.CasaDestino,
		DestinoID:                   resolucion.DestinoID,
		PermiteReconocimientoFacial: resolucion.PermiteReconocimientoFacial,
		InvitacionID:                resolucion.InvitacionID,
	})
}

// RevocarInvitacion revoca una invitación creada por la Persona autenticada.
func (h *Handler) RevocarInvitacion(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	if err := h.invitacionRepo.RevocarByIDAndPersonaCreadora(uint(id), personaID); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "invitación no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "invitación revocada"})
}

// GetMe devuelve el perfil de la Persona autenticada — la app lo usa tras
// loguear para decidir si falta completar nombre/apellidos.
func (h *Handler) GetMe(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	p, err := h.repo.FindByID(personaID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "persona no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, PersonaMeResponse{
		Telefono:             p.Telefono,
		Nombre:               p.Nombre,
		ApellidoPaterno:      p.ApellidoPaterno,
		ApellidoMaterno:      p.ApellidoMaterno,
		TelefonoVerificadoAt: p.TelefonoVerificadoAt,
	})
}

// ListarVisitasPendientes devuelve las visitas por aprobar en la casa de la
// Membresia activa de la Persona en el tenant pedido — el tenant se recibe
// explícito porque el JWT de Persona no lo lleva (identidad global).
func (h *Handler) ListarVisitasPendientes(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	tenantID64, err := strconv.ParseUint(c.Query("tenant_id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tenant_id inválido"})
		return
	}
	tenantID := uint(tenantID64)

	m, err := h.membresiaRepo.FindByPersonaAndTenant(personaID, tenantID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusForbidden, gin.H{"error": "no tienes una membresía en ese centro"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if m.Status != residente.ResidenteStatusActivo {
		c.JSON(http.StatusForbidden, gin.H{"error": "tu membresía en ese centro no está activa"})
		return
	}

	visitasPendientes, err := h.visitaRepo.WithContext(c.Request.Context()).
		FindPendientesByCasaDestino(tenantID, m.CasaDestino)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]visitas.VisitaResponse, 0, len(visitasPendientes))
	for _, v := range visitasPendientes {
		items = append(items, visitas.ToVisitaResponse(v))
	}
	c.JSON(http.StatusOK, gin.H{"visitas": items})
}

// ResponderVisita aprueba o rechaza una visita dirigida a la casa de la
// Membresia activa de la Persona en el tenant pedido.
func (h *Handler) ResponderVisita(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	tenantID64, err := strconv.ParseUint(c.Query("tenant_id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tenant_id inválido"})
		return
	}
	tenantID := uint(tenantID64)

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	m, err := h.membresiaRepo.FindByPersonaAndTenant(personaID, tenantID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusForbidden, gin.H{"error": "no tienes una membresía en ese centro"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if m.Status != residente.ResidenteStatusActivo {
		c.JSON(http.StatusForbidden, gin.H{"error": "tu membresía en ese centro no está activa"})
		return
	}

	visitaRepoCtx := h.visitaRepo.WithContext(c.Request.Context())
	if _, err := visitaRepoCtx.FindByIDAndCasaDestino(uint(id), tenantID, m.CasaDestino); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "visita no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var req ResponderVisitaPersonaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	estado := visitas.EstadoVisita(req.Estado)
	if estado != visitas.EstadoAprobado && estado != visitas.EstadoRechazado {
		c.JSON(http.StatusBadRequest, gin.H{"error": "estado debe ser APROBADO o RECHAZADO"})
		return
	}

	p, err := h.repo.FindByID(personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	nombre := p.Nombre + " " + p.ApellidoPaterno

	if err := visitaRepoCtx.UpdateEstado(uint(id), estado, visitas.AutorizadorResidente, nombre); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"estado": string(estado)})
}

// ListarMisMembresias devuelve todas las membresías (en cualquier tenant y
// status) de la Persona autenticada — la app la usa para resolver su
// sesión al reabrir: sin membresías → onboarding "unirse a centro"; con
// una pendiente → pantalla de espera; con una activa → dashboard.
func (h *Handler) ListarMisMembresias(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	list, err := h.membresiaRepo.FindByPersonaID(personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]MembresiaMeResponse, 0, len(list))
	for _, m := range list {
		nombreCentro := ""
		if t, err := h.tenantRepo.FindByID(m.TenantID); err == nil {
			nombreCentro = t.Nombre
		}
		items = append(items, MembresiaMeResponse{
			ID:           m.ID,
			TenantID:     m.TenantID,
			CentroNombre: nombreCentro,
			CasaDestino:  m.CasaDestino,
			Rol:          m.Rol,
			Status:       m.Status,
		})
	}
	c.JSON(http.StatusOK, gin.H{"membresias": items})
}

// PatchMe completa o actualiza nombre/apellidos/embedding de la Persona
// autenticada — usado por la app cuando GetMe devuelve un perfil vacío.
func (h *Handler) PatchMe(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	var req PatchPersonaMeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	nombre := strings.TrimSpace(req.Nombre)
	apellidoPaterno := strings.TrimSpace(req.ApellidoPaterno)
	if nombre == "" || apellidoPaterno == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nombre y apellido_paterno son requeridos"})
		return
	}

	p, err := h.repo.FindByID(personaID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "persona no encontrada"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	p.Nombre = nombre
	p.ApellidoPaterno = apellidoPaterno
	p.ApellidoMaterno = strings.TrimSpace(req.ApellidoMaterno)
	if err := h.repo.Update(p); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, PersonaMeResponse{
		Telefono:             p.Telefono,
		Nombre:               p.Nombre,
		ApellidoPaterno:      p.ApellidoPaterno,
		ApellidoMaterno:      p.ApellidoMaterno,
		TelefonoVerificadoAt: p.TelefonoVerificadoAt,
	})
}
