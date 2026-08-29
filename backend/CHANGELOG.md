# Changelog / Historial de Cambios

Este archivo documenta el historial de cambios, mejoras y lanzamientos del backend **AUTOnomIA**, organizado por versiones y fechas correspondientes

## Unreleased

> Cambios integrados en `dev` pero **no verificados contra un despliegue**. Las migraciones
> `000026`–`000030` requieren ejecutar `migrate up` antes de levantar el servidor.

### Features
- **PIN generado por el sistema** (migración `000051`): al unirse a un centro, la persona ya no
  elige su PIN; el backend genera uno de 5 dígitos, único dentro del centro, que no vuelve a
  cambiar. `POST /personas/me/membresias` deja de aceptar `pin` y
  `GET /personas/me/membresias` devuelve el campo `pin` en claro para que la app lo muestre en
  "Mi QR". La columna `membresias.pin` sigue guardando el hash bcrypt que compara el kiosko
  (también offline); la nueva `membresias.pin_codigo` guarda el código legible.
- **Activación de kioskos por Device Authorization Grant (RFC 8628)**: nueva tabla
  `device_authorizations` y endpoints `POST /auth/device/authorize`, `POST /auth/device/token`,
  `GET /device/validar`, `GET /device/pending` y `POST /device/:user_code/aprobar`. El dispositivo
  genera un código corto que el administrador aprueba desde el dashboard; se elimina la
  transcripción manual de la clave de kiosko (ADR 0019).
- **Auto-registro de residentes por código de instalación**: `CentroHabitacional` gana un `codigo`
  público y único. Nuevos endpoints públicos `GET /centros/buscar`,
  `GET /centros/:codigo/destinos`, `POST /centros/:codigo/residentes/auto-registro`,
  `GET /centros/:codigo/residentes/estado` y `POST /centros/:codigo/residentes/login`. El residente
  queda en estado `pendiente` hasta que el administrador lo aprueba (ADR 0020).
- **Aprobación de residentes desde el dashboard**: `GET /residentes/pendientes`,
  `POST /residentes/:id/aprobar` y `POST /residentes/:id/rechazar`.
- **Un tenant por administrador**: cada alta de admin crea su propio `CentroHabitacional`; los
  vigilantes heredan el tenant de quien los crea (ADR 0021).
- **Configuración del centro**: `CentroHabitacional` gana `tipo` y `descripcion`, editables desde
  el dashboard.
- **Endpoint de configuración para el kiosko**: `GET /kioskos/:id/config/mia`, autenticado con la
  sesión del propio kiosko en lugar del JWT de administrador.
- **Revocación de sesiones al eliminar un kiosko**: `DELETE /kioskos/:id` revoca las sesiones
  activas del dispositivo, que vuelve a la pantalla de activación.
- **Dashboard reorganizado**: navegación de seis secciones con menú de perfil; pestañas en
  Residentes (Activos / Solicitudes), Kioskos (Lista / Equipo) e Instalación
  (Destinos / Configuración). El asistente de configuración inicial pasa a tres pasos e incorpora
  el alta de destinos.

### Fixes
- Corregido el aislamiento multi-tenant: los registros de administrador asignaban `TenantID: 1`
  fijo, por lo que **todas las cuentas nuevas compartían datos** con el tenant heredado.
- Corregido `SQLSTATE 42702 — column reference "tenant_id" is ambiguous` en las consultas con JOIN
  de visitas y residentes, mediante el scope `ByTenantFor(tabla)`.
- Corregido `SQLSTATE 23502` al crear la configuración por defecto de un kiosko: `KioskoConfig` no
  declaraba `TenantID` en el struct de Go pese a existir la columna `NOT NULL`.
- `PATCH /tenants/:id` devuelve `409` con mensaje legible cuando el código de instalación ya está
  en uso, en lugar de un `500` genérico.
- El asistente de configuración inicial ya no reaparece en cada inicio de sesión: se decide por el
  estado del tenant, no por la ausencia de kioskos.

### Documentation
- **ADR 0019, 0020 y 0021**; ADR 0005 y 0008 marcados como reemplazados; corregido el título y el
  estado del ADR 0018, y anotada la divergencia entre `centro_habitacional_id` (documentado) y
  `tenant_id` (implementado).
- Nuevo índice de ADRs a nivel de producto en `docs/adr/` para decisiones que cruzan subproyectos,
  con el ADR 0001 del sistema de diseño unificado.
- READMEs reales para `kiosko/` y `residente/`, que hasta ahora eran la plantilla de Flutter.

### Pendiente
- Templates Admin: Template para chequeo de estadisticas generales siendo admin de condominio (de distintos accesos que se tengan)
- Rate limiting en `POST /auth/device/token`, hoy público y sin límite de *polling*.
- Unicidad de PIN por casa en el auto-registro de residentes.


## [v1.0] - 2026-06-20
Lanzamiento inicial de backend.

### Features
- Modelos iniciales: **Visitante**, **Usuario** y **Acceso** para registrar visitantes de accesos a condominios y admins (usuarios) de dichos accesos
- Servicios CRUD: Creación de capa de servicios CRUD para cada modelo
- Endpoints CRUD: Añadiendo endpoints CRUD para cada modelo
- Swaggo Documentacion: Añadiendo swaggo/gin-swagger para documentación openAPI

### Documentation
- **README**: Añadiendo readme basico del proyecto para despliegue y resumen del mismo
- **Github issue templates**: Añadiendo plantillas para feature o bug reports en issues
- **.env.example**: Añadiendo .env.example para mostrar vars necesarias en despliegue
- **adr documentation**: Añadiendo adr/ para registro de decisiones arquitectonicas en formato Nygard
