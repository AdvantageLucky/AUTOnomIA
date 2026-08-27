package auth

import (
	"context"
	"net/http"
	"strings"

	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"github.com/gin-gonic/gin"
)

// injectCtx mete la clave en gin Y en el contexto estándar del request.
// Gin usa su propio mapa interno (c.Set/Get), pero GORM y otros middlewares
// leen de c.Request.Context() — sin esta doble inyección los scopes de GORM
// (que llaman db.Statement.Context.Value) nunca ven los valores.
func injectCtx(c *gin.Context, key string, val any) {
	c.Set(key, val)
	c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), key, val))
}

// RequireAdmin valida el JWT del header "Authorization: Bearer <token>" y mete el admin_id,
// admin_rol y tenant_id en el contexto de gin y del request
func RequireAdmin(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		adminID, rol, tenantID, err := ParseAdminToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token invalido o expirado"})
			return
		}

		injectCtx(c, ctxkeys.AdminID, adminID)
		injectCtx(c, ctxkeys.AdminRol, rol)
		injectCtx(c, ctxkeys.TenantID, tenantID)
		c.Next()
	}
}

// RequireAdminRole verifica que el rol del admin autenticado esté en la lista permitida.
// Debe usarse después de RequireAdmin en la cadena de middlewares.
func RequireAdminRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		rol, _ := c.Get(ctxkeys.AdminRol)
		for _, r := range roles {
			if rol == r {
				c.Next()
				return
			}
		}
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "permisos insuficientes"})
	}
}

// RequireKiosko valida la sesion persistida del kiosko y mete el kiosko_id y tenant_id en el contexto
func RequireKiosko(sesionRepo *SesionRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		sesion, err := sesionRepo.FindActiveByToken(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "sesion invalida o revocada"})
			return
		}

		injectCtx(c, ctxkeys.KioskoID, sesion.KioskoID)
		injectCtx(c, ctxkeys.TenantID, sesion.TenantID)
		c.Next()
	}
}

// RequirePersona valida el JWT de la app Kigo y mete el persona_id en el
// contexto de gin y del request. A diferencia de RequireAdmin/RequireKiosko/
// RequireResidente, no inyecta tenant_id — Persona es global.
func RequirePersona(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := bearerToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token requerido"})
			return
		}

		personaID, err := ParsePersonaToken(token, secret)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token invalido o expirado"})
			return
		}

		injectCtx(c, ctxkeys.PersonaID, personaID)
		c.Next()
	}
}

func bearerToken(c *gin.Context) string {
	const prefix = "Bearer "
	header := c.GetHeader("Authorization")
	if strings.HasPrefix(header, prefix) {
		return strings.TrimPrefix(header, prefix)
	}
	// EventSource no puede enviar headers; acepta ?token= solo para SSE
	if q := c.Query("token"); q != "" {
		return q
	}
	return ""
}
