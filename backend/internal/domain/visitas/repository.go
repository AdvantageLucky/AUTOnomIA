package visitas

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"kigo-autonomia-backend/internal/domain/kiosko"
	"kigo-autonomia-backend/internal/platform/ctxkeys"

	"gorm.io/gorm"
)

type Repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) *Repository {
	return &Repository{db: db}
}

// WithContext retorna una instancia del repositorio vinculada al contexto HTTP de la petición
func (r *Repository) WithContext(ctx context.Context) *Repository {
	return &Repository{db: r.db.WithContext(ctx)}
}

// ByTenant filtra por el tenant del contexto. Para queries sin JOIN.
func ByTenant(db *gorm.DB) *gorm.DB {
	if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
		return db.Where("tenant_id = ?", tenantID)
	}
	return db
}

// ByTenantFor devuelve un scope que califica tenant_id con el nombre de tabla dado.
// Usar en queries con JOIN para evitar SQLSTATE 42702 (columna ambigua).
// Los scopes se ejecutan antes del parse del modelo, por lo que db.Statement.Table
// no es confiable — hay que capturar el nombre en la closure.
func ByTenantFor(table string) func(*gorm.DB) *gorm.DB {
	return func(db *gorm.DB) *gorm.DB {
		if tenantID, ok := db.Statement.Context.Value(ctxkeys.TenantID).(uint); ok && tenantID > 0 {
			return db.Where(table+".tenant_id = ?", tenantID)
		}
		return db
	}
}

func (r *Repository) Create(v *Visita) error {
	return r.db.Create(v).Error
}

// FindByClientID busca una visita ya creada con este client_id, para
// idempotencia: si el kiosko reenvía el mismo registro tras un corte de
// red a medio sync, regresa la visita existente en vez de duplicarla.
// nil, nil significa "no existe todavía" — no es un error.
func (r *Repository) FindByClientID(tenantID uint, clientID string) (*Visita, error) {
	var v Visita
	err := r.db.Where("tenant_id = ? AND client_id = ?", tenantID, clientID).First(&v).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &v, nil
}

// ClientIDPtr regresa nil si el client_id viene vacío (idempotencia
// opcional), o un puntero al valor si viene — evita guardar strings vacíos
// en una columna con unique index parcial (WHERE client_id IS NOT NULL).
func ClientIDPtr(clientID string) *string {
	if clientID == "" {
		return nil
	}
	return &clientID
}

// Los métodos que escanean a Visita deben encadenar Select("visitas.*") para evitar que las columnas
// id/created_at del join corrompan el resultado.
func (r *Repository) joinVisitasDeAdmin(adminID uint) *gorm.DB {
	return r.db.Scopes(ByTenantFor("visitas")).Model(&Visita{}).
		Joins("JOIN kioskos ON kioskos.id = visitas.kiosko_id").
		Where("kioskos.admin_id = ?", adminID)
}

// VisitaFiltros acota el listado de ListarVisitas. Todos los campos son opcionales.
type VisitaFiltros struct {
	KioskoID      *uint
	TipoDocumento *TipoDocumento
	TipoVisitante *TipoVisitante
	Estado        *EstadoVisita
	FechaDesde    *time.Time
	FechaHasta    *time.Time
	PersonaID     *uint
	Intervenida   *bool
	Q             string // ILIKE parcial sobre titular y curp
}

func (r *Repository) FindAllByAdminID(
	adminID uint,
	filtros VisitaFiltros,
	page, pageSize int,
) ([]Visita, int64, error) {
	query := func() *gorm.DB {
		q := r.joinVisitasDeAdmin(adminID)
		if filtros.KioskoID != nil {
			q = q.Where("visitas.kiosko_id = ?", *filtros.KioskoID)
		}
		if filtros.TipoDocumento != nil {
			q = q.Where("visitas.tipo_documento = ?", *filtros.TipoDocumento)
		}
		if filtros.TipoVisitante != nil {
			q = q.Where("visitas.tipo_visitante = ?", *filtros.TipoVisitante)
		}
		if filtros.Estado != nil {
			q = q.Where("visitas.estado = ?", *filtros.Estado)
		}
		if filtros.FechaDesde != nil {
			q = q.Where("visitas.created_at >= ?", *filtros.FechaDesde)
		}
		if filtros.FechaHasta != nil {
			q = q.Where("visitas.created_at < ?", *filtros.FechaHasta)
		}
		if filtros.PersonaID != nil {
			q = q.Where("visitas.persona_id = ?", *filtros.PersonaID)
		}
		if filtros.Intervenida != nil {
			q = q.Where("visitas.intervenida = ?", *filtros.Intervenida)
		}
		if filtros.Q != "" {
			like := "%" + filtros.Q + "%"
			q = q.Where(
				`(visitas.titular ILIKE ? OR visitas.curp ILIKE ?
				  OR visitas.casa_destino ILIKE ? OR visitas.placa ILIKE ?)`,
				like, like, like, like,
			)
		}
		return q
	}

	var total int64
	if err := query().Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	var list []Visita
	if err := query().
		Select("visitas.*").
		Order("visitas.created_at DESC").
		Limit(pageSize).
		Offset(offset).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	return list, total, nil
}

func (r *Repository) FindByIDAndAdminID(id, adminID uint) (*Visita, error) {
	var v Visita
	if err := r.joinVisitasDeAdmin(adminID).
		Select("visitas.*").
		Where("visitas.id = ?", id).
		First(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}

func (r *Repository) FindByCurpAndAdminID(curp string, adminID uint) ([]Visita, error) {
	var list []Visita
	if err := r.joinVisitasDeAdmin(adminID).
		Select("visitas.*").
		Where("visitas.curp = ?", curp).
		Order("visitas.created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindByIDAndKioskoID busca una visita por ID, acotada al kiosko dueño.
func (r *Repository) FindByIDAndKioskoID(id, kioskoID uint) (*Visita, error) {
	var v Visita
	if err := r.db.Scopes(ByTenant).
		Where("id = ? AND kiosko_id = ?", id, kioskoID).
		First(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}

// FindPendientesByKioskoID devuelve las visitas PENDIENTE de aprobación para un kiosko.
func (r *Repository) FindPendientesByKioskoID(kioskoID uint) ([]Visita, error) {
	var list []Visita
	if err := r.db.Scopes(ByTenant).
		Where("kiosko_id = ? AND estado = ?", kioskoID, EstadoPendiente).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindPendientesByCasaDestino devuelve las visitas PENDIENTE dirigidas a una
// casa dentro de un tenant — usado por el residente para ver qué le falta
// autorizar.
func (r *Repository) FindPendientesByCasaDestino(tenantID uint, casaDestino string) ([]Visita, error) {
	var list []Visita
	if err := r.db.
		Where("tenant_id = ? AND UPPER(casa_destino) = UPPER(?) AND estado = ?", tenantID, casaDestino, EstadoPendiente).
		Order("created_at DESC").
		Find(&list).Error; err != nil {
		return nil, err
	}
	return list, nil
}

// FindHistorialResueltasPorPersona devuelve, paginadas y de la mas reciente a
// la mas vieja, las visitas que esa Persona aprobo o rechazo desde la app.
//
// El filtro es por autorizado_por_persona_id y no por casa ni por rol: el
// historial responde "que resolvi yo". Asi quedan fuera lo que sigue
// pendiente, lo que resolvieron los demas miembros del domicilio y lo que
// despacharon el vigilante, el agente o el sistema — ninguno de ellos escribe
// esa columna.
func (r *Repository) FindHistorialResueltasPorPersona(
	tenantID uint,
	personaID uint,
	page, pageSize int,
) ([]Visita, int64, error) {
	query := func() *gorm.DB {
		return r.db.Model(&Visita{}).
			Where(
				"tenant_id = ? AND autorizado_por_persona_id = ?",
				tenantID, personaID,
			)
	}

	var total int64
	if err := query().Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var list []Visita
	if err := query().
		Order("created_at DESC").
		Limit(pageSize).
		Offset((page - 1) * pageSize).
		Find(&list).Error; err != nil {
		return nil, 0, err
	}

	return list, total, nil
}

// FindByIDAndCasaDestino busca una visita por ID acotada a la casa destino y
// tenant del residente autenticado — evita que un residente apruebe o
// rechace una visita de otra casa.
func (r *Repository) FindByIDAndCasaDestino(id, tenantID uint, casaDestino string) (*Visita, error) {
	var v Visita
	if err := r.db.
		Where("id = ? AND tenant_id = ? AND UPPER(casa_destino) = UPPER(?)", id, tenantID, casaDestino).
		First(&v).Error; err != nil {
		return nil, err
	}
	return &v, nil
}

// UpdateEstadoPorResidente resuelve una visita desde la app y deja anotado
// que Persona lo hizo, no solo que fue "un residente".
//
// Va aparte de UpdateEstado porque el resto de autorizadores (admin, agente,
// sistema) no son una Persona y no tienen id que guardar aqui.
func (r *Repository) UpdateEstadoPorResidente(
	id uint,
	estado EstadoVisita,
	personaID uint,
	nombre string,
) error {
	result := r.db.Scopes(ByTenant).Model(&Visita{}).Where("id = ?", id).Updates(map[string]any{
		"estado":                    estado,
		"autorizado_por_tipo":       AutorizadorResidente,
		"autorizado_por_nombre":     nombre,
		"autorizado_por_persona_id": personaID,
	})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// UpdateEstado cambia el estado de una visita y deja constancia de quién
// resolvió (autorizadoPorTipo: ver constantes Autorizador* en model.go).
func (r *Repository) UpdateEstado(id uint, estado EstadoVisita, autorizadoPorTipo, autorizadoPorNombre string) error {
	return r.UpdateEstadoConAdmin(id, estado, autorizadoPorTipo, autorizadoPorNombre, "", "")
}

// UpdateEstadoConAdmin es UpdateEstado pero además deja constancia de correo
// y rol cuando quien resolvió es un Admin (rol admin o vigilante) -- vacíos
// para los demás autorizadores (RESIDENTE, AGENTE, SISTEMA).
func (r *Repository) UpdateEstadoConAdmin(id uint, estado EstadoVisita, autorizadoPorTipo, autorizadoPorNombre, autorizadoPorCorreo, autorizadoPorRol string) error {
	result := r.db.Scopes(ByTenant).Model(&Visita{}).Where("id = ?", id).Updates(map[string]any{
		"estado":                estado,
		"autorizado_por_tipo":   autorizadoPorTipo,
		"autorizado_por_nombre": autorizadoPorNombre,
		"autorizado_por_correo": autorizadoPorCorreo,
		"autorizado_por_rol":    autorizadoPorRol,
	})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// HistorialPorCURP devuelve visitas previas de un CURP, de más reciente a más antigua
func (r *Repository) HistorialPorCURP(curp string) ([]Visita, error) {
	var visitas []Visita
	err := r.db.Scopes(ByTenant).Where("curp = ?", curp).Order("created_at DESC").Find(&visitas).Error
	return visitas, err
}

// HistorialPorPlaca devuelve visitas previas de una placa, de más reciente a más antigua.
// Es el historial de los accesos vehiculares que no capturan INE: ahí la matrícula
// es lo único que liga una visita con las anteriores (ADR-0024).
func (r *Repository) HistorialPorPlaca(placa string) ([]Visita, error) {
	var visitas []Visita
	err := r.db.Scopes(ByTenant).Where("placa = ?", placa).Order("created_at DESC").Find(&visitas).Error
	return visitas, err
}

// HistorialPorRostro devuelve las visitas previas cuya huella facial coincide
// con embedding por encima de umbralPct (0-100, similitud coseno).
//
// Es el identificador de ultimo recurso: en un flujo de solo rostro + destino
// no hay CURP ni placa, y sin esto ninguna persona era nunca recurrente por
// mucho que viniera a diario.
//
// El umbral es el mismo con el que el kiosko decide si dos caras son la misma
// (umbral_facial_pct), por coherencia: no tendria sentido que el kiosko diga
// "eres tu" y el historial diga que no.
func (r *Repository) HistorialPorRostro(embedding []float64, umbralPct int) ([]Visita, error) {
	if len(embedding) == 0 {
		return nil, nil
	}

	var candidatas []Visita
	err := r.db.Scopes(ByTenant).
		Where("embedding_rostro IS NOT NULL").
		Order("created_at DESC").
		Limit(maxVisitasEscaneadas).
		Find(&candidatas).Error
	if err != nil {
		return nil, err
	}

	umbral := float64(umbralPct) / 100
	var coincidencias []Visita
	for _, c := range candidatas {
		if similitudCoseno(c.EmbeddingRostro, embedding) >= umbral {
			coincidencias = append(coincidencias, c)
		}
	}
	return coincidencias, nil
}

// HistorialDeVisitante agrupa por CURP cuando la hay, si no por placa, y si
// tampoco hay, por parecido de rostro -- de las fuentes que fuentes deje
// prendidas (ver ScoreIaFuentes). Si el admin apagó todas, no hay con qué
// ligar la visita y se trata como primera vez, que es la opción segura.
//
// Nunca consulta con un identificador vacío: un `WHERE curp = ”` traeria todas
// las visitas sin INE del tenant y el análisis heredaría el historial de
// desconocidos — rechazos ajenos, visitas ajenas y, con autopass encendido,
// aprobaciones que nadie se ganó. El match por rostro respeta lo mismo: sin
// embedding no busca nada, en vez de traer el tenant entero.
func (r *Repository) HistorialDeVisitante(v Visita, umbralFacialPct int, fuentes ScoreIaFuentes) ([]Visita, error) {
	if fuentes.Documento && v.Curp != "" {
		return r.HistorialPorCURP(v.Curp)
	}
	if fuentes.Placa && v.Placa != "" {
		return r.HistorialPorPlaca(v.Placa)
	}
	if fuentes.Rostro {
		return r.HistorialPorRostro(v.EmbeddingRostro, umbralFacialPct)
	}
	return nil, nil
}

// GuardarAnalisisIA persiste el resultado del análisis de patrones (resumen
// narrativo del LLM + heurísticas de anomalía) de una visita walk-in. Si
// nuevoEstado no es nil, también actualiza el estado y queda registrado
// como AutorizadorAgente en la bitácora — mismo caso de uso que antes
// actualizaba solo el estado, ahora extendido para no descartar el
// resumen ni el score.
// GuardarAnalisisIA persiste el resultado del análisis de patrones (resumen
// narrativo del LLM + heurísticas de anomalía) de una visita walk-in. Si
// nuevoEstado no es nil, también actualiza el estado y queda registrado
// como AutorizadorAgente en la bitácora. intervenida solo se escribe cuando
// es true (la IA mandó esta visita a revisión) — nunca se fuerza a false,
// así que una vez marcada queda marcada para siempre, aunque una llamada
// posterior sobre la misma visita no vuelva a detectar la anomalía.
func (r *Repository) GuardarAnalisisIA(id uint, resumenIA string, scoreIA []byte, nuevoEstado *EstadoVisita, intervenida bool) error {
	updates := map[string]any{
		"resumen_ia": resumenIA,
		"score_ia":   scoreIA,
	}
	if nuevoEstado != nil {
		updates["estado"] = *nuevoEstado
		updates["autorizado_por_tipo"] = AutorizadorAgente
	}
	if intervenida {
		updates["intervenida"] = true
	}
	return r.db.Scopes(ByTenant).Model(&Visita{}).Where("id = ?", id).Updates(updates).Error
}

// GetKioskoConfig devuelve la config del kiosko, o valores por defecto si no existe aún
func (r *Repository) GetKioskoConfig(kioskoID uint) (*kiosko.KioskoConfig, error) {
	var cfg kiosko.KioskoConfig
	err := r.db.Scopes(ByTenant).Where("kiosko_id = ?", kioskoID).First(&cfg).Error
	if err == gorm.ErrRecordNotFound {
		return &kiosko.KioskoConfig{AutoPassHabilitado: true, UmbralFacialPct: 85, UmbralAutopassPct: 80}, nil
	}
	return &cfg, err
}

// GetKioskoTipo devuelve el tipo de acceso del kiosko (PEATONAL o VEHICULAR).
// La validación condicional lo necesita porque un acceso vehicular no exige INE
// al visitante sin invitación (ADR-0024).
func (r *Repository) GetKioskoTipo(kioskoID uint) (kiosko.TipoKiosko, error) {
	var k kiosko.Kiosko
	err := r.db.Scopes(ByTenant).Where("id = ?", kioskoID).First(&k).Error
	if err != nil {
		return kiosko.KioskoPeatonal, err
	}
	return k.Tipo, nil
}

// ListarEnPeriodo devuelve visitas creadas entre inicio y fin
func (r *Repository) ListarEnPeriodo(inicio, fin time.Time) ([]Visita, error) {
	var visitas []Visita
	err := r.db.Scopes(ByTenant).Where("created_at BETWEEN ? AND ?", inicio, fin).Find(&visitas).Error
	return visitas, err
}

// EstadisticasPersona agrega el historial de una Persona dentro del tenant
// actual — veces que ha entrado, cuándo fue la última vez, y la casa/destino
// que más se repite en su historial.
type EstadisticasPersona struct {
	VecesVisitado int        `json:"veces_visitado"`
	UltimaVisita  *time.Time `json:"ultima_visita,omitempty"`
	CasaHabitual  string     `json:"casa_habitual,omitempty"`
}

// EstadisticasPorPersona calcula EstadisticasPersona al leer (no al crear
// la visita) — no penaliza la latencia de login por PIN/rostro/QR, que es
// tiempo real con alguien esperando frente al kiosko. Nunca regresa error
// solo porque no hay historial: VecesVisitado=0 es una respuesta válida.
func (r *Repository) EstadisticasPorPersona(personaID uint) (*EstadisticasPersona, error) {
	stats := &EstadisticasPersona{}

	var count int64
	countQuery := r.db.Scopes(ByTenant).Model(&Visita{}).Where("persona_id = ?", personaID)
	if err := countQuery.Count(&count).Error; err != nil {
		return nil, err
	}
	stats.VecesVisitado = int(count)
	if count == 0 {
		return stats, nil
	}

	var ultima Visita
	if err := r.db.Scopes(ByTenant).Where("persona_id = ?", personaID).
		Order("created_at DESC").First(&ultima).Error; err != nil {
		return nil, err
	}
	stats.UltimaVisita = &ultima.CreatedAt

	var casaHabitual string
	if err := r.db.Scopes(ByTenant).Model(&Visita{}).
		Select("casa_destino").
		Where("persona_id = ?", personaID).
		Group("casa_destino").
		Order("COUNT(*) DESC").
		Limit(1).
		Scan(&casaHabitual).Error; err != nil {
		return nil, err
	}
	stats.CasaHabitual = casaHabitual

	return stats, nil
}

// TelefonoVerificadoDePersona regresa el teléfono de una Persona solo si ya
// verificó su cuenta -- así el admin ve contacto real, nunca el número "en
// blanco" de una invitación que nadie reclamó todavía, ni el de un
// desconocido sin cuenta de Kigo. Consulta la tabla personas directamente
// (sin importar el paquete persona) porque persona ya importa visitas y un
// import de vuelta crearía un ciclo.
func (r *Repository) TelefonoVerificadoDePersona(personaID uint) string {
	var telefono string
	err := r.db.Table("personas").
		Select("telefono").
		Where("id = ? AND telefono_verificado_at IS NOT NULL", personaID).
		Scan(&telefono).Error
	if err != nil {
		return ""
	}
	return telefono
}

// ResolverDestinoID busca el Destino cuyo nombre coincide (sin distinguir
// mayúsculas ni espacios, mismo idioma que destinos.FindCanonicoPorTenant)
// con el texto libre que llega en CasaDestino desde el kiosko. Consulta la
// tabla destinos directamente para no importar ese paquete desde visitas
// (mismo motivo que TelefonoVerificadoDePersona). nil si no hay match --
// registros sin destino resoluble se guardan igual, solo sin el enlace.
func (r *Repository) ResolverDestinoID(tenantID uint, casaDestino string) *uint {
	if casaDestino == "" {
		return nil
	}
	var id uint
	err := r.db.Table("destinos").
		Select("id").
		Where("tenant_id = ? AND UPPER(TRIM(nombre)) = UPPER(TRIM(?)) AND deleted_at IS NULL", tenantID, casaDestino).
		Scan(&id).Error
	if err != nil || id == 0 {
		return nil
	}
	return &id
}

// CurpDePersona consulta la CURP registrada en el perfil de una Persona --
// para un residente que entra por PIN/rostro la Visita nunca captura CURP
// (no se escanea INE en cada entrada), pero su perfil ya la tiene si la
// dio al enrolarse. Vacío si no se conoce.
func (r *Repository) CurpDePersona(personaID uint) string {
	var curp string
	err := r.db.Table("personas").
		Select("curp").
		Where("id = ?", personaID).
		Scan(&curp).Error
	if err != nil {
		return ""
	}
	return curp
}

// AdminInfo es el subconjunto de datos del Admin que se guarda en la
// bitácora de una visita al momento de resolverla.
type AdminInfo struct {
	Nombre string
	Correo string
	Rol    string
}

// InfoDeAdmin consulta la tabla admins directamente (sin importar el
// paquete admin, mismo motivo que TelefonoVerificadoDePersona) para armar
// el nombre completo, correo y rol de quien resolvió una visita.
func (r *Repository) InfoDeAdmin(adminID uint) AdminInfo {
	var fila struct {
		Nombre          string
		ApellidoPaterno string
		Correo          string
		Rol             string
	}
	err := r.db.Table("admins").
		Select("nombre, apellido_paterno, correo, rol").
		Where("id = ?", adminID).
		Scan(&fila).Error
	if err != nil {
		return AdminInfo{}
	}
	nombre := strings.TrimSpace(fila.Nombre + " " + fila.ApellidoPaterno)
	if nombre == "" {
		nombre = fmt.Sprintf("admin #%d", adminID)
	}
	return AdminInfo{Nombre: nombre, Correo: fila.Correo, Rol: fila.Rol}
}
