package persona

import (
	"crypto/ed25519"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/tenant"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type Handler struct {
	repo           *Repository
	otpRepo        *OtpRepository
	sender         OtpSender
	emailSender    OtpSender
	jwtSecret      string
	qrPrivateKey   ed25519.PrivateKey
	qrPublicKey    ed25519.PublicKey
	membresiaRepo  *residente.MembresiaRepository
	tenantRepo     tenant.Repository
	invitacionRepo *invitaciones.Repository
	visitaRepo     *visitas.Repository
	destinoRepo    *destinos.Repository
	uploadsDir     string
	llmURL         string
	kigoVerify     KigoVerifyConfig
	kigoVerifyRepo *KigoVerifyRepository
	pushSender     residente.PushSender
}

func NewHandler(
	repo *Repository,
	otpRepo *OtpRepository,
	sender OtpSender,
	emailSender OtpSender,
	jwtSecret, qrEd25519PrivateKeySeed string,
	membresiaRepo *residente.MembresiaRepository,
	tenantRepo tenant.Repository,
	invitacionRepo *invitaciones.Repository,
	visitaRepo *visitas.Repository,
	destinoRepo *destinos.Repository,
	uploadsDir string,
	llmURL string,
	kigoVerify KigoVerifyConfig,
	kigoVerifyRepo *KigoVerifyRepository,
	pushSender residente.PushSender,
) *Handler {
	seed, err := hex.DecodeString(qrEd25519PrivateKeySeed)
	if err != nil || len(seed) != ed25519.SeedSize {
		panic("QR_ED25519_PRIVATE_KEY inválido: se esperaban 32 bytes en hex")
	}
	privKey := ed25519.NewKeyFromSeed(seed)
	return &Handler{
		repo:           repo,
		otpRepo:        otpRepo,
		sender:         sender,
		emailSender:    emailSender,
		jwtSecret:      jwtSecret,
		qrPrivateKey:   privKey,
		qrPublicKey:    privKey.Public().(ed25519.PublicKey),
		membresiaRepo:  membresiaRepo,
		tenantRepo:     tenantRepo,
		invitacionRepo: invitacionRepo,
		visitaRepo:     visitaRepo,
		destinoRepo:    destinoRepo,
		uploadsDir:     uploadsDir,
		kigoVerify:     kigoVerify,
		kigoVerifyRepo: kigoVerifyRepo,
		llmURL:         llmURL,
		pushSender:     pushSender,
	}
}

// ListarDestinos devuelve el/los destino(s) propio(s) de la Persona en el
// tenant pedido — la app necesita el ID real (no solo el nombre) para crear
// una invitación con destino_id. Antes devolvía TODOS los destinos del
// tenant: el selector de "Nueva Invitación" mostraba cualquier casa del
// fraccionamiento, no solo la del residente que invita (CrearInvitacion ya
// rechaza invitar a una casa ajena, pero el dropdown seguía ofreciéndolas).
// Verifica membresía activa igual que ListarVisitasPendientes: el tenant no
// viene del JWT (identidad global).
func (h *Handler) ListarDestinos(c *gin.Context) {
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

	list, err := h.destinoRepo.FindByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Mismo criterio case/espacio-insensible que CrearInvitacion: Destino.Nombre
	// y Membresia.CasaDestino son texto libre, no una FK.
	items := make([]gin.H, 0, 1)
	for _, d := range list {
		if strings.EqualFold(strings.TrimSpace(d.Nombre), strings.TrimSpace(m.CasaDestino)) {
			items = append(items, gin.H{"id": d.ID, "nombre": d.Nombre})
		}
	}
	c.JSON(http.StatusOK, gin.H{"destinos": items})
}

// ListarCompanerosCasa devuelve los demás miembros activos de la misma
// casa_destino que la Persona autenticada, dentro del tenant pedido. Mismo
// patrón de verificación que ListarDestinos: el tenant no viene del JWT
// (identidad global), se exige membresía activa propia contra ese tenant
// antes de tocar cualquier dato de otros residentes. Solo expone
// nombre_completo y rol — nunca teléfono, CURP ni foto.
func (h *Handler) ListarCompanerosCasa(c *gin.Context) {
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

	companeros, err := h.membresiaRepo.FindCompanerosCasa(tenantID, m.CasaDestino, personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if companeros == nil {
		companeros = make([]residente.CompaneroCasa, 0)
	}

	c.JSON(http.StatusOK, gin.H{"companeros": companeros, "casa_destino": m.CasaDestino})
}

// ListarDestinosPorCodigo devuelve los destinos de un centro por su código
// público — a diferencia de ListarDestinos, no exige membresía activa: es
// justo el picker que se usa *antes* de unirse (UnirseCentro), para no
// depender de que la persona escriba la casa/calle a mano sin saber el
// formato exacto que usó el admin. Requiere Persona autenticada (no es
// anónimo) como mitigación — expone la estructura del centro, no datos de
// residentes.
func (h *Handler) ListarDestinosPorCodigo(c *gin.Context) {
	codigo := strings.TrimSpace(c.Param("codigo"))

	t, err := h.tenantRepo.FindByCodigo(codigo)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "centro no encontrado"})
		return
	}

	list, err := h.destinoRepo.FindByTenantID(t.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]gin.H, 0, len(list))
	for _, d := range list {
		items = append(items, gin.H{
			"id": d.ID, "nombre": d.Nombre, "calle": d.Calle,
			"tipo": string(d.Tipo), "numero": d.Numero,
		})
	}
	c.JSON(http.StatusOK, gin.H{"destinos": items})
}

// SolicitarOTP genera y "manda" (ver OtpSender) un código de verificación
// para un teléfono. Válido 5 minutos.
func (h *Handler) SolicitarOTP(c *gin.Context) {
	var req SolicitarOtpRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.Telefono = NormalizarTelefono(req.Telefono)

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

	// Con correo, se manda ahí en vez de por SMS — el teléfono sigue siendo
	// el ancla de identidad (la solicitud y la verificación siguen
	// buscándose por teléfono), esto solo decide el canal de entrega.
	destino, sender := req.Telefono, h.sender
	if req.Correo != "" {
		destino, sender = req.Correo, h.emailSender
	}
	if err := sender.Enviar(c.Request.Context(), destino, codigo); err != nil {
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
	req.Telefono = NormalizarTelefono(req.Telefono)

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
	firma := FirmarPersonaID(personaID, h.qrPrivateKey)
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

	// La app no muestra el directorio completo de casas (evita exponer todo
	// el directorio a quien solo tiene el código público) — la persona
	// escribe la casa a mano, así que se normaliza sin distinguir mayúsculas
	// ni espacios contra el destino real y se guarda su Nombre exacto, nunca
	// lo que tecleó. Sin coincidencia, error específico sin listar opciones.
	destino, err := h.destinoRepo.FindCanonicoPorTenant(req.CasaDestino, t.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "no encontramos esa casa en este centro — verifica mayúsculas, espacios y el número exacto"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	casaDestino := destino.Nombre

	existente, err := h.membresiaRepo.FindByPersonaAndTenant(personaID, t.ID)
	if err == nil {
		if existente.Status != residente.ResidenteStatusRechazado {
			c.JSON(http.StatusConflict, gin.H{"error": "ya tienes una membresía en este centro"})
			return
		}
		existente.CasaDestino = casaDestino
		// El PIN no cambia: quien ya tenía uno vuelve a entrar con el
		// mismo aunque el admin lo haya rechazado y se reinscriba.
		if existente.PinCodigo == "" {
			codigo, hash, err := h.generarPinParaTenant(t.ID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo generar el PIN"})
				return
			}
			existente.PinCodigo = codigo
			existente.Pin = hash
		}
		existente.Status = residente.ResidenteStatusPendiente
		if err := h.membresiaRepo.Update(existente); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, MembresiaResponse{
			ID:          existente.ID,
			TenantID:    existente.TenantID,
			CasaDestino: existente.CasaDestino,
			Status:      existente.Status,
			Pin:         existente.PinCodigo,
		})
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	codigo, hash, err := h.generarPinParaTenant(t.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo generar el PIN"})
		return
	}

	m := &residente.Membresia{
		PersonaID:   personaID,
		TenantID:    t.ID,
		CasaDestino: casaDestino,
		Pin:         hash,
		PinCodigo:   codigo,
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
		Status:      m.Status,
		Pin:         m.PinCodigo,
	})
}

// generarPinParaTenant reúne los PIN ya ocupados en el centro (los
// generados, en claro, y los viejos, solo como hash) y pide uno libre.
func (h *Handler) generarPinParaTenant(tenantID uint) (codigo string, hash string, err error) {
	usados, err := h.membresiaRepo.FindPinCodigosPorTenant(tenantID)
	if err != nil {
		return "", "", err
	}
	legacy, err := h.membresiaRepo.FindPinHashesLegacyPorTenant(tenantID)
	if err != nil {
		return "", "", err
	}
	return generarPin(usados, legacy)
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

	// Sin esto, cualquier residente autenticado podía mandar cualquier
	// destino_id del tenant (o de otro tenant) y crear una invitación a una
	// casa que no es la suya -- Membresia no tiene FK a Destino, solo
	// CasaDestino (texto), así que la única forma de verificar "es tu
	// casa" es resolver el Destino y comparar su Nombre contra eso.
	destino, err := h.destinoRepo.FindByID(req.DestinoID)
	// Comparación case/espacio-insensible: es el mismo criterio que usa
	// FindCompanerosCasa (UPPER(TRIM(...))) para decidir "misma casa" --
	// Membresia.CasaDestino y Destino.Nombre son texto libre, no una FK,
	// así que una diferencia de mayúsculas entre ambos no debe bloquear al
	// dueño real de invitar a su propia casa.
	if err != nil || destino.TenantID != req.TenantID ||
		!strings.EqualFold(strings.TrimSpace(destino.Nombre), strings.TrimSpace(m.CasaDestino)) {
		c.JSON(http.StatusForbidden, gin.H{"error": "solo puedes invitar a tu propia casa"})
		return
	}

	invitado, err := h.repo.FindOrCreateByTelefono(NormalizarTelefono(req.TelefonoInvitado))
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

	// Sin max_usos explícito, una invitación PERSONAL (un solo invitado)
	// quedaba usable un número ilimitado de veces -- kigo-app nunca manda
	// max_usos, así que en la práctica NINGUNA invitación tenía límite.
	// GRUPAL sí puede quedar sin límite si el creador no pone uno.
	maxUsos := req.MaxUsos
	if maxUsos == nil && req.Tipo == invitaciones.InvitacionPersonal {
		uno := 1
		maxUsos = &uno
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
		MaxUsos:                     maxUsos,
		ExpiresAt:                   req.ExpiresAt,
	}
	if err := h.invitacionRepo.Create(inv); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, invitaciones.ToInvitacionResponse(inv, true))

	// Push solo si el invitado ya tenía cuenta verificada antes de esta
	// invitación (TelefonoVerificadoAt != nil) -- a alguien sin cuenta
	// (Persona "en blanco" recién creada por FindOrCreateByTelefono) no
	// hay a quién avisarle todavía; se entera cuando se registre y su
	// "recibidas" ya la tenga esperando.
	if h.pushSender != nil && invitado.TelefonoVerificadoAt != nil &&
		invitado.DeviceToken != nil && *invitado.DeviceToken != "" {
		cuerpo := "Tienes una invitación nueva a " + destino.Nombre
		if err := h.pushSender.Send(c.Request.Context(), *invitado.DeviceToken, "Nueva invitación", cuerpo); err != nil {
			log.Printf("CrearInvitacion: error mandando push a persona %d: %v", invitado.ID, err)
		}
	}
}

// ListarInvitaciones lista las invitaciones creadas por la Persona
// autenticada. El token sí viaja aquí (a diferencia de ValidarInvitacion,
// que es público): esta lista solo la ve quien las creó, y necesita el
// token para poder compartir de nuevo el link de una invitación existente.
func (h *Handler) ListarInvitaciones(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	list, err := h.invitacionRepo.FindByPersonaCreadora(personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := make([]invitaciones.InvitacionResponse, len(list))
	for i, inv := range list {
		resp[i] = invitaciones.ToInvitacionResponse(&inv, true)
	}
	c.JSON(http.StatusOK, resp)
}

// ListarContactosFrecuentes lista, una vez por persona, a quien la Persona
// autenticada ya invitó antes -- para "invitar de nuevo" sin volver a
// teclear teléfono y nombre. Ver invitaciones.Repository.FindContactosFrecuentes.
func (h *Handler) ListarContactosFrecuentes(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	list, err := h.invitacionRepo.FindContactosFrecuentes(personaID, 20)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"contactos": list})
}

// ListarInvitacionesRecibidas lista las invitaciones activas dirigidas a la
// Persona autenticada — lo que ve en "invitaciones recibidas" en kigo-app.
// A diferencia de ListarInvitaciones (las que ella creó), estas ya llegan
// adjuntas por teléfono desde CrearInvitacion; no hace falta "reclamarlas".
func (h *Handler) ListarInvitacionesRecibidas(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	list, err := h.invitacionRepo.FindByPersonaInvitada(personaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	resp := make([]invitaciones.InvitacionRecibidaResponse, len(list))
	for i, inv := range list {
		var casaDestino string
		if d, err := h.destinoRepo.FindByID(inv.DestinoID); err == nil {
			casaDestino = d.Nombre
		}
		var nombreInvita string
		if inv.PersonaCreadoraID != nil {
			if p, err := h.repo.FindByID(*inv.PersonaCreadoraID); err == nil {
				nombreInvita = p.Nombre
			}
		}
		resp[i] = invitaciones.ToInvitacionRecibidaResponse(&inv, casaDestino, nombreInvita)
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

	if !VerificarFirma(req.PersonaID, req.Firma, h.qrPublicKey) {
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

	// Un "miembro" es de la casa — no deja rastro de Visita. Un "invitado"
	// sí: el QR personal ya lo identifica por completo (no requiere
	// capturas adicionales), así que la Visita se crea de una vez, APROBADO,
	// y se descuenta el uso de la invitación.
	var visitaID *uint
	var visitaCreada *visitas.Visita
	if resolucion.Estado == EstadoQRInvitado && invitacion != nil {
		if req.ClientID != "" {
			existente, err := h.visitaRepo.WithContext(c.Request.Context()).FindByClientID(tenantID, req.ClientID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			if existente != nil {
				c.JSON(http.StatusOK, VerificarQRResponse{
					Estado:                      resolucion.Estado,
					Nombre:                      existente.Titular,
					CasaDestino:                 existente.CasaDestino,
					DestinoID:                   resolucion.DestinoID,
					PermiteReconocimientoFacial: resolucion.PermiteReconocimientoFacial,
					InvitacionID:                resolucion.InvitacionID,
					VisitaID:                    &existente.ID,
				})
				return
			}
		}

		destino, err := h.destinoRepo.FindByID(*resolucion.DestinoID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "no se pudo resolver el destino de la invitación"})
			return
		}
		resolucion.CasaDestino = destino.Nombre

		kioskoID := c.MustGet(ctxkeys.KioskoID).(uint)
		v := &visitas.Visita{
			TenantID:      tenantID,
			Titular:       resolucion.Nombre,
			TipoVisitante: visitas.TipoConInvitacion,
			TipoDocumento: visitas.DocumentoQR,
			CasaDestino:   destino.Nombre,
			Estado:        visitas.EstadoAprobado,
			KioskoID:      kioskoID,
			ClientID:      visitas.ClientIDPtr(req.ClientID),
			PersonaID:     &req.PersonaID,
		}
		if err := h.visitaRepo.WithContext(c.Request.Context()).Create(v); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "error registrando la visita"})
			return
		}
		if err := h.invitacionRepo.IncrementarUso(invitacion.ID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		visitaID = &v.ID
		visitaCreada = v
	}

	c.JSON(http.StatusOK, VerificarQRResponse{
		Estado:                      resolucion.Estado,
		Nombre:                      resolucion.Nombre,
		CasaDestino:                 resolucion.CasaDestino,
		DestinoID:                   resolucion.DestinoID,
		PermiteReconocimientoFacial: resolucion.PermiteReconocimientoFacial,
		InvitacionID:                resolucion.InvitacionID,
		VisitaID:                    visitaID,
	})

	if visitaCreada != nil {
		go visitas.AnalizarYGuardarInformativo(h.visitaRepo, tenantID, *visitaCreada, h.llmURL)
	}
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

	c.JSON(http.StatusOK, toPersonaMeResponse(p))
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
		item := visitas.ToVisitaResponse(v)
		// El residente no debe ver el análisis de IA (resumen/heurísticas) de
		// sus solicitudes pendientes — es información para el dashboard admin,
		// no para la app de residente. rechazado_previo en particular podría
		// filtrar que hubo un rechazo en otra casa del mismo tenant.
		item.ResumenIA = nil
		item.ScoreIA = nil
		item.Estadisticas = nil
		items = append(items, item)
	}
	c.JSON(http.StatusOK, gin.H{"visitas": items})
}

// ListarHistorialVisitas devuelve las visitas que la Persona autenticada
// aprobo o rechazo desde la app, de la mas reciente a la mas vieja. Es el
// complemento de ListarVisitasPendientes: alli va lo que falta autorizar,
// aqui lo que uno mismo ya resolvio.
//
// La membresia se sigue comprobando aunque el filtro no use la casa: sin ella
// la Persona no tiene por que leer nada de ese tenant.
func (h *Handler) ListarHistorialVisitas(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	tenantID64, err := strconv.ParseUint(c.Query("tenant_id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "tenant_id invalido"})
		return
	}
	tenantID := uint(tenantID64)

	page, pageSize := 1, 30
	if v, err := strconv.Atoi(c.Query("page")); err == nil && v > 0 {
		page = v
	}
	if v, err := strconv.Atoi(c.Query("page_size")); err == nil && v > 0 && v <= 100 {
		pageSize = v
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

	historial, total, err := h.visitaRepo.WithContext(c.Request.Context()).
		FindHistorialResueltasPorPersona(tenantID, personaID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	items := make([]visitas.VisitaResponse, 0, len(historial))
	for _, v := range historial {
		item := visitas.ToVisitaResponse(v)
		// Mismo recorte que en pendientes: el analisis de IA es para el
		// dashboard admin, no para la app del residente.
		item.ResumenIA = nil
		item.ScoreIA = nil
		item.Estadisticas = nil
		items = append(items, item)
	}
	c.JSON(http.StatusOK, gin.H{
		"visitas":   items,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
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

	if err := visitaRepoCtx.UpdateEstadoPorResidente(uint(id), estado, personaID, nombre); err != nil {
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
	for i := range list {
		m := &list[i]
		nombreCentro := ""
		if t, err := h.tenantRepo.FindByID(m.TenantID); err == nil {
			nombreCentro = t.Nombre
		}
		// Membresías de antes del PIN generado: no hay código en claro que
		// mostrar, así que se les asigna uno aquí, la primera vez que la
		// app las pide. A partir de ese momento ya no cambia.
		if m.PinCodigo == "" {
			if codigo, hash, err := h.generarPinParaTenant(m.TenantID); err == nil {
				m.PinCodigo = codigo
				m.Pin = hash
				if err := h.membresiaRepo.Update(m); err != nil {
					m.PinCodigo = ""
				}
			}
		}
		items = append(items, MembresiaMeResponse{
			ID:           m.ID,
			TenantID:     m.TenantID,
			CentroNombre: nombreCentro,
			CasaDestino:  m.CasaDestino,
			Status:       m.Status,
			Pin:          m.PinCodigo,
		})
	}
	c.JSON(http.StatusOK, gin.H{"membresias": items})
}

// PatchMe completa o actualiza nombre/apellidos de la Persona autenticada
// — usado por la app cuando GetMe devuelve un perfil vacío.
func (h *Handler) RegistrarDeviceToken(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	var req DeviceTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.repo.UpdateDeviceToken(personaID, req.DeviceToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

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

	c.JSON(http.StatusOK, toPersonaMeResponse(p))
}

// CompletarIdentidad cierra el wizard de INE+rostro del onboarding: recibe
// nombre/apellidos/CURP confirmados, la foto de la INE, la foto de rostro y
// el embedding facial (192-dim MobileFaceNet, calculado on-device por la
// app) en una sola llamada multipart, y completa el perfil de la Persona
// autenticada de un tirón — ver spec 2026-08-17-kigo-app-rediseno-design.md §10.
func (h *Handler) CompletarIdentidad(c *gin.Context) {
	personaID := c.MustGet(ctxkeys.PersonaID).(uint)

	nombre := strings.TrimSpace(c.PostForm("nombre"))
	apellidoPaterno := strings.TrimSpace(c.PostForm("apellido_paterno"))
	apellidoMaterno := strings.TrimSpace(c.PostForm("apellido_materno"))
	curp := strings.TrimSpace(c.PostForm("curp"))
	if nombre == "" || apellidoPaterno == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nombre y apellido_paterno son requeridos"})
		return
	}

	var embedding []float64
	if err := json.Unmarshal([]byte(c.PostForm("embedding")), &embedding); err != nil || len(embedding) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "embedding inválido o vacío"})
		return
	}

	fotoIneHeader, err := c.FormFile("foto_documento")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento requerida"})
		return
	}
	fotoRostroHeader, err := c.FormFile("foto_rostro")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "foto_rostro requerida"})
		return
	}

	fotoIneUrl, err := visitas.GuardarFotoVisitante(c, fotoIneHeader, h.uploadsDir)
	if err != nil {
		if errors.Is(err, visitas.ErrFormatoFotoInvalido) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_documento: " + err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	fotoRostroUrl, err := visitas.GuardarFotoVisitante(c, fotoRostroHeader, h.uploadsDir)
	if err != nil {
		if errors.Is(err, visitas.ErrFormatoFotoInvalido) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "foto_rostro: " + err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
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
	p.ApellidoMaterno = apellidoMaterno
	p.Curp = curp
	p.FotoIneUrl = fotoIneUrl
	p.FotoCaraUrl = fotoRostroUrl
	p.Embedding = residente.FloatArray(embedding)
	if err := h.repo.Update(p); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, toPersonaMeResponse(p))
}
