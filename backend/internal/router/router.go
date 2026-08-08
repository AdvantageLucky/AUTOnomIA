package router

import (
	"kigo-autonomia-backend/configs"
	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/invitaciones"
	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/tenant" // <-- Nuevo import issue 21
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
	registerResidenteRoutes(api, db, cfg.JWTSecret, cfg.UploadsDir)
	registerInvitacionesRoutes(api, db, cfg.JWTSecret)
	// <-- Nueva Linea de issue 21
	registerTenantRoutes(api, db)

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

	// El dashboard admin se edita seguido en desarrollo; sin esto el navegador
	// cachea app.js/styles.css con heurísticas propias y los cambios no se ven
	// aunque el archivo en disco ya esté actualizado.
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
	authHandler := auth.NewHandler(adminRepo, kioskoRepo, sesionRepo, jwtSecret)
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
	kioskoHandler := kiosko.NewHandler(kioskoRepo)
	sesionRepo := auth.NewSesionRepository(db)

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

	// el kiosko se suscribe al stream SSE de su propia config
	k := rg.Group("/kioskos/:id/config")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.GET("/stream", kioskoHandler.StreamConfig)
	}
}

// registerVisitaRoutes registra las rutas de visitas: registro desde el kiosko (sesion) y
// consulta del admin (JWT).
func registerVisitaRoutes(rg *gin.RouterGroup, db *gorm.DB, cfg *configs.Config, hub *sse.Hub) {
	visitaRepo := visitas.NewRepository(db)
	visitaHandler := visitas.NewHandler(visitaRepo, cfg.UploadsDir, cfg.LLMUrl, hub)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: solo registra visitas
	v := rg.Group("/kioskos/:id/visitas")
	v.Use(auth.RequireKiosko(sesionRepo))
	{
		v.POST("/", visitaHandler.RegisterVisita)
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
		a.DELETE("/:id", destinoHandler.EliminarDestino)
	}
}

func registerInvitacionesRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	invRepo := invitaciones.NewRepository(db)
	invHandler := invitaciones.NewHandler(invRepo, db)
	sesionRepo := auth.NewSesionRepository(db)

	// app residente: crea, lista y revoca sus invitaciones
	r := rg.Group("/residentes/me/invitaciones")
	r.Use(auth.RequireResidente(jwtSecret))
	{
		r.POST("/", invHandler.CrearInvitacion)
		r.GET("/", invHandler.ListarInvitaciones)
		r.DELETE("/:id", invHandler.RevocarInvitacion)
	}

	// kiosko: valida un token y registra su uso
	k := rg.Group("/kioskos/:id/invitaciones")
	k.Use(auth.RequireKiosko(sesionRepo))
	{
		k.GET("/validar", invHandler.ValidarInvitacion)
		k.POST("/:token/usar", invHandler.UsarInvitacion)
	}
}

// registerResidenteRoutes registra rutas de residente: auto-registro público, login, y
// endpoints autenticados para la app del residente y el dashboard admin.
func registerResidenteRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string, uploadsDir string) {
	residenteRepo := residente.NewRepository(db)
	destinoRepo := destinos.NewRepository(db)
	residenteHandler := residente.NewHandler(residenteRepo, destinoRepo, jwtSecret, db, uploadsDir)

	// público: búsqueda de centro, auto-registro y consulta de estado
	rg.GET("/centros/buscar", residenteHandler.BuscarCentro)
	rg.POST("/centros/:codigo/residentes/auto-registro", residenteHandler.AutoRegistrar)
	rg.GET("/centros/:codigo/residentes/estado", residenteHandler.ConsultarEstado)

	// login público
	rg.POST("/auth/residente/login", residenteHandler.LoginResidente)

	// app residente: rutas protegidas por JWT de residente
	r := rg.Group("/residentes")
	r.Use(auth.RequireResidente(jwtSecret))
	{
		r.GET("/me", residenteHandler.GetMe)
	}

	// kiosko: valida PIN de residente usando la sesión del kiosko
	sesionRepo := auth.NewSesionRepository(db)
	kPin := rg.Group("/kioskos/:id/residentes")
	kPin.Use(auth.RequireKiosko(sesionRepo))
	{
		kPin.POST("/login", residenteHandler.LoginResidenteDesdeKiosko)
	}

	// admin: crea residentes y los lista por kiosko
	a := rg.Group("/kioskos/:id/residentes")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.GET("/", residenteHandler.ListarResidentesPorAcceso)
	}

	adminR := rg.Group("/residentes")
	adminR.Use(auth.RequireAdmin(jwtSecret))
	{
		adminR.POST("/", residenteHandler.CrearResidente)
		adminR.GET("/", residenteHandler.ListarResidentesAdmin)
		adminR.GET("/pendientes", residenteHandler.ListarPendientes)
		adminR.POST("/:id/aprobar", residenteHandler.AprobarResidente)
		adminR.POST("/:id/rechazar", residenteHandler.RechazarResidente)
	}
}

// registerTenantRoutes registra las rutas para la gestión de fraccionamientos (tenants).
// Por ahora están desprotegidas para facilitar las pruebas locales.
func registerTenantRoutes(rg *gin.RouterGroup, db *gorm.DB) {
	tenantRepo := tenant.NewRepository(db)
	tenantHandler := tenant.NewHandler(tenantRepo)

	t := rg.Group("/tenants")
	{
		t.POST("/", tenantHandler.CreateTenant)
		t.GET("/:id", tenantHandler.GetTenant)
		t.PATCH("/:id", tenantHandler.PatchTenant)
	}
}
