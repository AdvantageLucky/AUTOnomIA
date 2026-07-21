/*
Package router
Inicializacion y registro de rutas (apps)
*/
package router

import (
	"kigo-autonomia-backend/configs"
	"kigo-autonomia-backend/internal/domain/acceso"
	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/destinos"
	"kigo-autonomia-backend/internal/domain/residente"
	"kigo-autonomia-backend/internal/domain/visitas"

	"github.com/gin-gonic/gin"
	swaggerfiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"
)

// Setup registra todas las rutas del server
func Setup(db *gorm.DB, cfg *configs.Config) *gin.Engine {
	r := gin.Default()
	api := r.Group("/api/v1")

	registerAuthRoutes(api, db, cfg.JWTSecret)
	registerAdminRoutes(api, db, cfg.JWTSecret)
	registerAccesoRoutes(api, db, cfg.JWTSecret)
	registerVisitaRoutes(api, db, cfg)
	registerDestinosRoutes(api, db, cfg.JWTSecret)
	registerResidenteRoutes(api, db, cfg.JWTSecret)

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))
	r.Static("/admin", "./web/admin")
	r.Static("/uploads/visitantes", "./web/uploads/visitantes")

	return r
}

func registerAuthRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	adminRepo := admin.NewRepository(db)
	accesoRepo := acceso.NewRepository(db)
	sesionRepo := auth.NewSesionRepository(db)
	authHandler := auth.NewHandler(adminRepo, accesoRepo, sesionRepo, jwtSecret)

	g := rg.Group("/auth")
	{
		g.POST("/sign-in", authHandler.RegisterAdminWithMailAndPassword)
		g.POST("/login", authHandler.LoginAdminWithMailAndPassword)
		g.POST("/google", authHandler.LoginWithGoogle)
		g.POST("/google/sign-in", authHandler.RegisterWithGoogle)
		g.POST("/acceso/login", authHandler.LoginAcceso)
		g.POST("/acceso/:id/revocar", auth.RequireAdmin(jwtSecret), authHandler.RevocarSesionAcceso)
	}
}

func registerAdminRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	adminRepo := admin.NewRepository(db)
	adminHandler := admin.NewHandler(adminRepo)

	a := rg.Group("/admins")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.GET("/:id", adminHandler.GetAdminByID)
		a.PATCH("/:id", adminHandler.PatchAdmin)
		a.DELETE("/:id", adminHandler.DeleteAdmin)
	}
}

func registerAccesoRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	accesoRepo := acceso.NewRepository(db)
	accesoHandler := acceso.NewHandler(accesoRepo)

	a := rg.Group("/accesos")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.POST("/", accesoHandler.RegisterAccess)
		a.GET("/", accesoHandler.GetAllAccess)
		a.GET("/:id", accesoHandler.GetAccessByID)
		a.PATCH("/:id", accesoHandler.PatchAccess)
		a.DELETE("/:id", accesoHandler.DeleteAccess)
		a.GET("/:id/config", accesoHandler.GetConfig)
		a.PATCH("/:id/config", accesoHandler.PatchConfig)
	}
}

// registerVisitaRoutes registra las rutas de visitas: registro desde el kiosko (sesion) y
// consulta del admin (JWT).
func registerVisitaRoutes(rg *gin.RouterGroup, db *gorm.DB, cfg *configs.Config) {
	visitaRepo := visitas.NewRepository(db)
	visitaHandler := visitas.NewHandler(visitaRepo, cfg.UploadsDir)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: solo registra visitas
	v := rg.Group("/accesos/:id/visitas")
	v.Use(auth.RequireAcceso(sesionRepo))
	{
		v.POST("/", visitaHandler.RegisterVisita)
	}

	// dashboard admin: lectura paginada, detalle e historial
	d := rg.Group("/visitas")
	d.Use(auth.RequireAdmin(cfg.JWTSecret))
	{
		d.GET("/", visitaHandler.ListarVisitas)
		d.GET("/buscar", visitaHandler.HistorialVisita)
		d.GET("/:id", visitaHandler.GetVisitaByID)
		d.PATCH("/:id/estado", visitaHandler.ActualizarEstado)
	}
}

// registerDestinosRoutes registra rutas de destinos: listado por el kiosko (sesion) y
// creación/gestión por el admin (JWT).
func registerDestinosRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	destinoRepo := destinos.NewRepository(db)
	destinoHandler := destinos.NewHandler(destinoRepo)
	sesionRepo := auth.NewSesionRepository(db)

	// kiosko: solo lee destinos de su acceso
	k := rg.Group("/accesos/:id/destinos")
	k.Use(auth.RequireAcceso(sesionRepo))
	{
		k.GET("/", destinoHandler.ListarDestinosPorAcceso)
	}

	// admin: crea destinos para sus accesos
	a := rg.Group("/accesos/:id/destinos")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.POST("/", destinoHandler.CrearDestino)
	}
}

// registerResidenteRoutes registra rutas de residente: login (público) y endpoints
// autenticados para la app del residente y el dashboard admin.
func registerResidenteRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	residenteRepo := residente.NewRepository(db)
	residenteHandler := residente.NewHandler(residenteRepo, jwtSecret)

	// login público
	rg.POST("/auth/residente/login", residenteHandler.LoginResidente)

	// app residente: rutas protegidas por JWT de residente
	r := rg.Group("/residentes")
	r.Use(auth.RequireResidente(jwtSecret))
	{
		r.GET("/me", residenteHandler.GetMe)
	}

	// admin: crea residentes y los lista por acceso
	a := rg.Group("/accesos/:id/residentes")
	a.Use(auth.RequireAdmin(jwtSecret))
	{
		a.GET("/", residenteHandler.ListarResidentesPorAcceso)
	}

	adminR := rg.Group("/residentes")
	adminR.Use(auth.RequireAdmin(jwtSecret))
	{
		adminR.POST("/", residenteHandler.CrearResidente)
		adminR.GET("/", residenteHandler.ListarResidentesAdmin)
	}
}
