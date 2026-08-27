package router

import (
	"context"
	"log"

	"kigo-autonomia-backend/configs"
	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/domain/persona"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/sync"
	"kigo-autonomia-backend/internal/domain/tenant"
	"kigo-autonomia-backend/internal/domain/visitas"
	"kigo-autonomia-backend/internal/platform/sse"

	"github.com/gin-gonic/gin"
	swaggerfiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"
)

// Setup registra todas las rutas del server
func Setup(db *gorm.DB, cfg *configs.Config) *gin.Engine {
	r := gin.Default()
	api := r.Group("/api/v1")

	hub := sse.NewHub()
	visitas.IniciarAgenteReportes(db, cfg.LLMUrl)

	registerAuthRoutes(api, db, cfg.JWTSecret, cfg.PublicURL)
	registerAdminRoutes(api, db, cfg.JWTSecret)
	registerKioskoRoutes(api, db, cfg.JWTSecret)
	registerVisitaRoutes(api, db, cfg, hub)
	registerDestinosRoutes(api, db, cfg.JWTSecret)
	registerKioskoLoginRoutes(api, db)
	registerInvitacionesRoutes(api, db, cfg.JWTSecret, cfg.UploadsDir)
	registerSyncRoutes(api, db)
	registerPersonaRoutes(api, db, cfg)
	registerTenantRoutes(api, db, cfg.JWTSecret)

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

	// El dashboard admin se edita seguido en desarrollo; sin esto el navegador
	// cachea app.js/styles.css con heurísticas propias y los cambios no se ven
	// aunque el archivo en disco ya esté actualizado.
	// El botón de Google del dashboard lee window.__GOOGLE_CLIENT_ID__ — se
	// sirve como JS generado en vez de hardcodearlo en index.html para que
	// sea la misma variable de entorno la que valida el backend
	// (auth.LoginWithGoogle), nunca dos copias que se puedan desalinear.
	// Va fuera de /admin: un GET explícito bajo el mismo prefijo que ya usa
	// adminAssets.Static (wildcard *filepath) hace panic a gin al arrancar
	// (conflicto de rutas en su árbol de radix).
	r.GET("/admin-config.js", func(c *gin.Context) {
		c.Header("Content-Type", "application/javascript")
		c.String(200, "window.__GOOGLE_CLIENT_ID__ = %q;", cfg.GoogleClientID)
	})

	adminAssets := r.Group("/admin")
	adminAssets.Use(func(c *gin.Context) {
		c.Header("Cache-Control", "no-store")
		c.Next()
	})
	adminAssets.Static("/", "./web/admin")

	r.Static("/uploads/visitantes", cfg.UploadsDir)
	r.Static("/uploads/caras", cfg.UploadsDir+"/caras")

	return r
}

func registerAuthRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret, publicURL string) {
	adminRepo := admin.NewRepository(db)
	kioskoRepo := kiosko.NewRepository(db)
	sesionRepo := auth.NewSesionRepository(db)
	tenantRepo := tenant.NewRepository(db)
	authHandler := auth.NewHandler(adminRepo, kioskoRepo, sesionRepo, tenantRepo, jwtSecret)
	deviceRepo := auth.NewDeviceRepository(db)
	deviceHandler := auth.NewDeviceHandler(deviceRepo, sesionRepo, kioskoRepo, publicURL)

	g := rg.Group("/auth")
	{
		g.POST("/sign-in", authHandler.RegisterAdminWithMailAndPassword)
		g.POST("/login", authHandler.LoginAdminWithMailAndPassword)
		g.POST("/google", authHandler.LoginWithGoogle)
		g.POST("/google/sign-in", authHandler.RegisterWithGoogle)
		g.POST("/kiosko/login", authHandler.LoginKiosko)
		g.POST("/kiosko/:id/revocar", auth.RequireAdmin(jwtSecret), authHandler.RevocarSesionKiosko)
		g.POST("/device/authorize", deviceHandler.SolicitarCodigo)
		g.POST("/device/token", deviceHandler.ObtenerToken)
	}

	d := rg.Group("/device")
	d.Use(auth.RequireAdmin(jwtSecret))
	{
		d.GET("/validar", deviceHandler.ValidarCodigo)
		d.GET("/pending", deviceHandler.ListarPendientes)
		d.POST("/:user_code/aprobar", deviceHandler.AprobarDispositivo)
	}
}

func registerAdminRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	adminRepo := admin.NewRepository(db)
	adminHandler := admin.NewHandler(adminRepo)

	a := rg.Group("/admins")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.GET("/", adminHandler.ListarAdmins)
		a.GET("/:id", adminHandler.GetAdminByID)
		a.PATCH("/:id", adminHandler.PatchAdmin)
		a.DELETE("/:id", adminHandler.DeleteAdmin)
	}
}

func registerKioskoRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	kioskoRepo := kiosko.NewRepository(db)
	sesionRepo := auth.NewSesionRepository(db)
	kioskoHandler := kiosko.NewHandler(kioskoRepo, sesionRepo.RevokeAllByKioskoID)

	a := rg.Group("/kioskos")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.POST("/", kioskoHandler.RegisterKiosko)
		a.GET("/", kioskoHandler.GetAllKioskos)
		a.GET("/:id", kioskoHandler.GetKioskoByID)
		a.PATCH("/:id", kioskoHandler.PatchKiosko)
		a.DELETE("/:id", kioskoHandler.DeleteKiosko)
		a.GET("/:id/config", kioskoHandler.GetConfig)
		a.PATCH("/:id/config", kioskoHandler.PatchConfig)
	}

	// el kiosko consulta y se suscribe al stream de su propia config, autenticado por sesión
	k := rg.Group("/kioskos/:id/config")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		// path distinto a "/kioskos/:id/config" (reservado para el admin, autenticado por JWT)
		// para evitar un conflicto de ruta duplicada en gin con el mismo método y path.
		k.GET("/mia", kioskoHandler.GetConfigDesdeKiosko)
		k.GET("/stream", kioskoHandler.StreamConfig)
	}
}

// pushSender decide entre FCM real y el falso que solo loguea, según si hay
// credencial de Firebase configurada — sin ella el servidor sigue
// arrancando (dev/local sin FCM configurado no debe tumbar todo).
func pushSender(cfg *configs.Config) residente.PushSender {
	if cfg.FirebaseCredentialsPath == "" {
		return residente.LogPushSender{}
	}
	sender, err := residente.NewFirebasePushSender(context.Background(), cfg.FirebaseCredentialsPath)
	if err != nil {
		log.Printf("pushSender: no se pudo inicializar FCM (%v), usando el notificador falso", err)
		return residente.LogPushSender{}
	}
	return sender
}

// emailOtpSender decide entre correo real por SMTP y el falso que solo
// loguea — sin SMTP_USER/SMTP_PASSWORD configurados, sigue con el falso en
// vez de fallar cada solicitud que pida enviar el código por correo.
func emailOtpSender(cfg *configs.Config) persona.OtpSender {
	if cfg.SMTPUser == "" || cfg.SMTPPassword == "" {
		return persona.LogOtpSender{}
	}
	return persona.EmailOtpSender{
		Host:     cfg.SMTPHost,
		Port:     cfg.SMTPPort,
		User:     cfg.SMTPUser,
		Password: cfg.SMTPPassword,
	}
}

// registerVisitaRoutes registra las rutas de visitas: registro desde el kiosko (sesion) y
// consulta del admin (JWT).
func registerVisitaRoutes(rg *gin.RouterGroup, db *gorm.DB, cfg *configs.Config, hub *sse.Hub) {
	visitaRepo := visitas.NewRepository(db)
	notificador := persona.NewPushNotificador(persona.NewRepository(db), pushSender(cfg))
	visitaHandler := visitas.NewHandler(visitaRepo, cfg.UploadsDir, cfg.LLMUrl, hub, notificador)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: solo registra visitas
	v := rg.Group("/kioskos/:id/visitas")
	v.Use(auth.RequireKiosko(sesionRepo))
	{
		v.POST("/", visitaHandler.RegisterVisita)
		v.GET("/recurrencia", visitaHandler.ConsultarRecurrencia)
		v.GET("/:visitaId", visitaHandler.GetVisitaEstado)
	}

	// dashboard admin: lectura paginada, detalle, historial y reportes
	d := rg.Group("/visitas")
	d.Use(auth.RequireAdmin(cfg.JWTSecret))
	{
		d.GET("/", visitaHandler.ListarVisitas)
		d.GET("/buscar", visitaHandler.HistorialVisita)
		d.GET("/reportes", visitaHandler.ListarReportes)
		d.GET("/:id", visitaHandler.GetVisitaByID)
		d.PATCH("/:id/estado", visitaHandler.ActualizarEstado)
	}

	// SSE stream — admin de cualquier rol puede suscribirse
	stream := rg.Group("/kioskos/solicitudes")
	stream.Use(auth.RequireAdmin(cfg.JWTSecret))
	{
		stream.GET("/stream", visitaHandler.StreamSolicitudes)
	}
}

// registerDestinosRoutes registra rutas de destinos: listado por el kiosko (sesion) y
// creación/gestión por el admin (JWT).
func registerDestinosRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	destinoRepo := destinos.NewRepository(db)
	destinoHandler := destinos.NewHandler(destinoRepo)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: lista todos los destinos del tenant (ruta legacy mantenida para la app)
	k := rg.Group("/kioskos/:id/destinos")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.GET("/", destinoHandler.ListarDestinosPorAcceso)
	}

	// admin: CRUD de destinos a nivel del tenant
	a := rg.Group("/destinos")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.GET("/", destinoHandler.ListarDestinos)
		a.POST("/", destinoHandler.CrearDestino)
		a.POST("/lote", destinoHandler.CrearDestinosLote)
		a.DELETE("/:id", destinoHandler.EliminarDestino)
	}
}

// registerSyncRoutes registra el endpoint de solo lectura que arma el
// snapshot offline del kiosko: destinos, residentes con huella facial e
// invitaciones activas del tenant.
func registerSyncRoutes(rg *gin.RouterGroup, db *gorm.DB) {
	destinoRepo := destinos.NewRepository(db)
	personaRepo := persona.NewRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	syncHandler := sync.NewHandler(destinoRepo, personaRepo, invitacionRepo)
	sesionRepo := auth.NewSesionRepository(db)

	k := rg.Group("/kioskos/:id/sync")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.GET("/snapshot", syncHandler.GetSnapshot)
	}
}

// registerKioskoLoginRoutes registra el login del kiosko por PIN y por
// rostro — mismos paths que antes, ahora resuelven contra Persona+Membresia
// en vez de Residente (ver spec 2026-08-26-eliminar-residente-legacy-design.md).
func registerKioskoLoginRoutes(rg *gin.RouterGroup, db *gorm.DB) {
	personaRepo := persona.NewRepository(db)
	visitaRepo := visitas.NewRepository(db)
	kioskoLoginHandler := persona.NewKioskoLoginHandler(personaRepo, visitaRepo, db)
	sesionRepo := auth.NewSesionRepository(db)

	kPin := rg.Group("/kioskos/:id/residentes")
	kPin.Use(auth.RequireKiosko(sesionRepo))
	{
		kPin.POST("/login", kioskoLoginHandler.LoginDesdeKiosko)
		kPin.POST("/verificar-rostro", kioskoLoginHandler.VerificarRostroDesdeKiosko)
	}
}

func registerInvitacionesRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret, uploadsDir string) {
	invRepo := invitaciones.NewRepository(db)
	invHandler := invitaciones.NewHandler(invRepo, db, uploadsDir)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: valida un token y registra su uso
	k := rg.Group("/kioskos/:id/invitaciones")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.GET("/validar", invHandler.ValidarInvitacion)
		k.POST("/:token/usar", invHandler.UsarInvitacion)
	}
}

// registerTenantRoutes registra las rutas para la gestión de fraccionamientos (tenants).
func registerTenantRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	tenantRepo := tenant.NewRepository(db)
	tenantHandler := tenant.NewHandler(tenantRepo)

	t := rg.Group("/tenants")
	t.Use(auth.RequireAdmin(jwtSecret))
	{
		t.GET("/:id", tenantHandler.GetTenant)
		t.PATCH("/:id", tenantHandler.PatchTenant)
	}
}

// registerPersonaRoutes registra las rutas de la app Kigo: registro/login
// por teléfono+OTP (público) y el QR personal (autenticado).
func registerPersonaRoutes(rg *gin.RouterGroup, db *gorm.DB, cfg *configs.Config) {
	personaRepo := persona.NewRepository(db)
	otpRepo := persona.NewOtpRepository(db)
	membresiaRepo := residente.NewMembresiaRepository(db)
	tenantRepo := tenant.NewRepository(db)
	invitacionRepo := invitaciones.NewRepository(db)
	visitaRepo := visitas.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)
	personaHandler := persona.NewHandler(
		personaRepo, otpRepo, persona.LogOtpSender{}, emailOtpSender(cfg),
		cfg.JWTSecret, cfg.QRMasterSecret,
		membresiaRepo, tenantRepo, invitacionRepo, visitaRepo, destinoRepo, cfg.UploadsDir,
	)

	rg.POST("/personas/registro/solicitar-otp", personaHandler.SolicitarOTP)
	rg.POST("/personas/registro/verificar-otp", personaHandler.VerificarOTP)

	p := rg.Group("/personas/me")
	p.Use(auth.RequirePersona(cfg.JWTSecret))
	{
		p.GET("", personaHandler.GetMe)
		p.PATCH("", personaHandler.PatchMe)
		p.POST("/identidad", personaHandler.CompletarIdentidad)
		p.POST("/device-token", personaHandler.RegistrarDeviceToken)
		p.GET("/qr", personaHandler.GetQR)
		p.POST("/membresias", personaHandler.UnirseCentro)
		p.GET("/membresias", personaHandler.ListarMisMembresias)
		p.GET("/destinos", personaHandler.ListarDestinos)
		p.GET("/centros/:codigo/destinos", personaHandler.ListarDestinosPorCodigo)
		p.POST("/invitaciones", personaHandler.CrearInvitacion)
		p.GET("/invitaciones", personaHandler.ListarInvitaciones)
		p.DELETE("/invitaciones/:id", personaHandler.RevocarInvitacion)
	}

	pv := rg.Group("/personas/me/visitas")
	pv.Use(auth.RequirePersona(cfg.JWTSecret))
	{
		pv.GET("/pendientes", personaHandler.ListarVisitasPendientes)
		pv.PATCH("/:id/estado", personaHandler.ResponderVisita)
	}

	sesionRepo := auth.NewSesionRepository(db)
	k := rg.Group("/kioskos/:id/personas")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.POST("/verificar-qr", personaHandler.VerificarQR)
	}

	a := rg.Group("/membresias")
	a.Use(auth.RequireAdmin(cfg.JWTSecret))
	{
		membresiaHandler := residente.NewMembresiaHandler(membresiaRepo)
		a.GET("/pendientes", membresiaHandler.ListarPendientes)
		a.POST("/:id/aprobar", membresiaHandler.Aprobar)
		a.POST("/:id/rechazar", membresiaHandler.Rechazar)
	}
}
