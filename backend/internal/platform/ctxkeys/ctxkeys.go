/*
Package ctxkeys

Constantes de llaves usadas con gin.Context.Set/Get para pasar la identidad
autenticada (admin_id via JWT, acceso_id via sesion de kiosko) de los
middlewares de internal/domain/auth/ a los handlers de cada dominio.

Vive en su propio paquete (sin depender de auth/ ni de ningun dominio) para
evitar un ciclo de imports: auth/ depende de acceso/ y admin/ para resolver
login, pero acceso/, admin/ y visitantes/ tambien necesitan leer estas llaves
en sus handlers.
*/
package ctxkeys

const (
	AdminID     = "admin_id"
	AccesoID    = "acceso_id"
	ResidenteID = "residente_id"
)
