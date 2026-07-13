/*
Package router
Inicializacion y registro de rutas (apps)
Este paquete funciona para inicializar el router de gin y añadir
las rutas que contienen encapsuladas su propia informacion de la app

function Setup(db *gorm.DB) -> *gin.Engine
Inicializa el engine de gin y registra rutas de apps que contiene
toda su informacion contenida en si misma. Para el registro de rutas
necesitamos de funciones helper que registran las rutas por app y en grupo.
Se usa db de tipo gorm.DB para comunicar modelos y services con la gorm y su orm

func register<Dominio>Routes(rg *gin.RouterGroup, db *gorm.DB)
Una funcion helper por dominio que registra sus rutas (ver registerAdminRoutes,
registerAccesoRoutes y registerVisitanteRoutes mas abajo)
*/
package router

import (
	"kigo-autonomia-backend/internal/domain/acceso"
	"kigo-autonomia-backend/internal/domain/admin"
	"kigo-autonomia-backend/internal/domain/auth"
	"kigo-autonomia-backend/internal/domain/visitantes"

	"github.com/gin-gonic/gin"
	swaggerfiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"
)

// Setup registra todas las rutas del server
func Setup(db *gorm.DB, jwtSecret string) *gin.Engine {
	r := gin.Default()
	api := r.Group("/api/v1")

	registerAuthRoutes(api, db, jwtSecret)
	registerAdminRoutes(api, db, jwtSecret)
	registerAccesoRoutes(api, db, jwtSecret)
	registerVisitanteRoutes(api, db, jwtSecret)

	// documentacion OpenAPI/Swagger, regenerar con `go tool swag init -g cmd/server/main.go --parseInternal -o docs`
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerfiles.Handler))

	// dashboard de admin: HTML/CSS/JS estatico, sin build step, consume la API en /api/v1 desde el navegador
	r.Static("/admin", "./web/admin")

	// fotos de visitantes: el kiosko aun no sube archivos via la API (VisitanteRequest.FotoURL es
	// una URL que el cliente ya trae resuelta), esto solo sirve lo que haya en disco como estatico
	r.Static("/uploads/visitantes", "./web/uploads/visitantes")

	return r
}

// registerAuthRoutes registra las rutas de login/registro de Admin (JWT) y de kiosko (sesion)
func registerAuthRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	adminRepo := admin.NewRepository(db)
	accesoRepo := acceso.NewRepository(db)
	sesionRepo := auth.NewSesionRepository(db)
	authHandler := auth.NewHandler(adminRepo, accesoRepo, sesionRepo, jwtSecret)

	g := rg.Group("/auth")
	{
		g.POST("/sign-in", authHandler.RegisterAdmin)
		g.POST("/login", authHandler.LoginAdmin)
		g.POST("/acceso/login", authHandler.LoginAcceso)
		g.POST("/acceso/:id/revocar", auth.RequireAdmin(jwtSecret), authHandler.RevocarSesionAcceso)
	}
}

// registerAdminRoutes registra las rutas de admins, protegidas con el JWT del admin autenticado
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

// registerAccesoRoutes registra las rutas de accesos, protegidas con el JWT del admin autenticado
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
	}
}

// registerVisitanteRoutes registra las rutas de visitantes: el registro/gestion de un visitante va anidado
// bajo el Acceso por el que entro, protegido por la sesion del kiosko (RequireAcceso); la consulta para el
// dashboard del admin va plana en /visitantes, protegida por el JWT del admin (RequireAdmin)
func registerVisitanteRoutes(rg *gin.RouterGroup, db *gorm.DB, jwtSecret string) {
	visitanteRepo := visitantes.NewRepository(db)
	visitanteHandler := visitantes.NewHandler(visitanteRepo)
	sesionRepo := auth.NewSesionRepository(db)

	// el kiosko solo registra visitantes; no tiene ninguna ruta de lectura (ver internal/domain/visitantes/handlers.go)
	v := rg.Group("/accesos/:id/visitantes")
	v.Use(auth.RequireAcceso(sesionRepo))
	{
		v.POST("/", visitanteHandler.RegisterVisitante)
	}

	d := rg.Group("/visitantes")
	d.Use(auth.RequireAdmin(jwtSecret))
	{
		d.GET("/", visitanteHandler.ListarVisitantes)
		d.GET("/buscar", visitanteHandler.HistorialVisitante)
		d.GET("/:id", visitanteHandler.GetVisitanteByIDAndAdminID)
	}
}
