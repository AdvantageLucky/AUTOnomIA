# Architecture Decision Records (ADR)

Registro de decisiones arquitectónicas significativas del backend de AUTOnomIA, en formato [Nygard](https://github.com/joelparkerhenderson/architecture-decision-record).

Cada ADR es inmutable una vez aceptado: si una decisión cambia, se crea un ADR nuevo que la reemplaza y se marca el anterior como `Superseded by NNNN`.

Las decisiones que cruzan más de un subproyecto (backend, kiosko, residente) viven en el índice de nivel de producto: [`docs/adr/`](../../../docs/adr/README.md).

## Índice de Decisiones
- [0001 - Stack tecnológico base](0001-stack-tecnologico.md)
- [0002 - Documentación de API con OpenAPI/swaggo](0002-openapi-swaggo.md)
- [0003 - Organización por dominio (4 archivos)](0003-organizacion-por-dominio.md)
- [0004 - Autenticación dual (Mecanismos para Admin y Kiosko)](0004-auth-dual-mecanismo.md)
- [0005 - Generación de clave de kiosko](0005-generacion-clave-kiosko.md) *(reemplazado por 0019)*
- [0006 - Visita como evento de kiosko, no como entidad de persona](0006-visita-como-evento-no-entidad.md)
- [0007 - Dominio destinos con titular para verificación STT del kiosko](0007-destinos-con-titular-para-verificacion-stt.md)
- [0008 - Autenticación del residente por PIN numérico](0008-auth-residente-por-pin.md) *(reemplazado por 0020)*
- [0009 - Google OAuth para el dashboard admin sin bundler ni backend de sesión](0009-google-oauth-en-dashboard-sin-bundler.md)
- [0010 - i18n y theming en el dashboard con JS y CSS vanilla](0010-i18n-y-theming-en-dashboard-vanilla.md)
- [0011 - Configuración parametrizable por kiosko](0011-configuracion-parametrizable-kiosko.md)
- [0012 - Búsqueda fuzzy multi-campo en bitácora de visitas](0012-busqueda-fuzzy-multicampo-visitas.md)
- [0013 - Aprobación manual de solicitudes desde el dashboard](0013-solicitudes-aprobacion-manual-dashboard.md)
- [0014 - WebSockets para solicitudes en tiempo real (pendiente)](0014-websockets-solicitudes-tiempo-real.md)
- [0015 - Alcance de residentes en escenario multi-kiosko](0015-residentes-alcance-multikiosko.md)
- [0016 - TipoVisitante y refactor de campos INE en KioskoConfig](0016-tipo-visitante-y-refactor-kioskoconfig-ine.md) *(reemplazado parcialmente por 0024)*
- [0017 - Invitaciones con token opaco generado por el servidor](0017-invitaciones-token-opaco.md)
- [0018 - Arquitectura Multi-tenant con CentroHabitacional](0018-multitenancy-centro-habitacional.md)
- [0019 - Activación de kioskos con Device Authorization Grant (RFC 8628)](0019-activacion-kiosko-device-authorization-grant.md)
- [0020 - Auto-registro de residentes por código de instalación](0020-auto-registro-residente-por-codigo-instalacion.md)
- [0021 - Aislamiento multi-tenant: un tenant por admin y scopes calificados en JOIN](0021-aislamiento-tenant-por-admin-y-scopes-calificados.md)
- [0022 - El tipo de kiosko viaja en su configuración](0022-tipo-kiosko-en-config.md)
- [0023 - Las capturas del invitado viajan en `UsarInvitacion`](0023-capturas-de-invitado-al-usar-invitacion.md)
- [0024 - La placa identifica la visita en un acceso vehicular](0024-identidad-por-placa-en-acceso-vehicular.md)

---

## Relación entre Decisiones Arquitectónicas

La arquitectura del backend de AUTOnomIA está diseñada para mantener un servidor *stateless*, separando las responsabilidades lógicas en cuatro ejes principales:

1. **Modelado de Dominio y Datos ([0003](0003-organizacion-por-dominio.md), [0006](0006-visita-como-evento-no-entidad.md), [0007](0007-destinos-con-titular-para-verificacion-stt.md), [0015](0015-residentes-alcance-multikiosko.md), [0016](0016-tipo-visitante-y-refactor-kioskoconfig-ine.md), [0017](0017-invitaciones-token-opaco.md), [0018](0018-multitenancy-centro-habitacional.md), [0021](0021-aislamiento-tenant-por-admin-y-scopes-calificados.md)):**
   El núcleo de la base de datos no registra "visitantes" estáticos, sino **eventos inmutables de visita** asignados a un **destino validado**. El sistema distingue entre un visitante inesperado y un invitado pre-autorizado[cite: 23]. Para agilizar el acceso, se generan invitaciones mediante tokens opacos (semillas aleatorias) que permiten revocación instantánea vía *soft-delete*[cite: 22]. Todo esto opera bajo el alcance de residentes a nivel de comunidad[cite: 24] y la separación *multi-tenant*, donde cada administrador es dueño de su propia instalación y las consultas con JOIN califican explícitamente la columna de tenant.

2. **Autenticación Especializada ([0004](0004-auth-dual-mecanismo.md), [0009](0009-google-oauth-en-dashboard-sin-bundler.md), [0019](0019-activacion-kiosko-device-authorization-grant.md), [0020](0020-auto-registro-residente-por-codigo-instalacion.md)):**
   Se aplica el principio de menor privilegio dependiendo de la interfaz. Los **Kioskos** se activan mediante el *Device Authorization Grant* (RFC 8628) —el dispositivo genera un código corto que el admin aprueba desde el dashboard— y luego operan con una sesión persistida revocable. Los **Residentes** se auto-registran con el código público de su instalación y entran con un PIN numérico, sujeto a aprobación previa del administrador. Los **Administradores** acceden mediante correo/contraseña o Google Identity Services (GSI).

3. **Operación e Interfaces ([0001](0001-stack-tecnologico.md), [0010](0010-i18n-y-theming-en-dashboard-vanilla.md), [0011](0011-configuracion-parametrizable-kiosko.md), [0012](0012-busqueda-fuzzy-multicampo-visitas.md), [0013](0013-solicitudes-aprobacion-manual-dashboard.md), [0022](0022-tipo-kiosko-en-config.md), [0023](0023-capturas-de-invitado-al-usar-invitacion.md)):**
   La validación de la documentación oficial (INE) se procesa condicionalmente en el *handler* del servidor; es siempre obligatoria para visitantes inesperados, pero configurable para invitados[cite: 23]. Esa configuración llega a la terminal por el mismo canal que su tipo de acceso —peatonal o vehicular—, de modo que un solo APK atiende ambas casetas y el admin decide cuál es cada una desde el dashboard. El panel administrativo gestiona la internacionalización (i18n) sin dependencias externas, y la parametrización física mitiga inconsistencias del escaneo OCR mediante búsquedas *fuzzy*.

4. **Sincronización ([0014](0014-websockets-solicitudes-tiempo-real.md)):**
   La latencia actual en la aprobación manual de visitas mediante *polling* será reemplazada por una infraestructura de WebSockets para garantizar comunicación bidireccional en tiempo real entre los accesos físicos y el panel de vigilancia.

*(Para revisar los diagramas de estado y flujos de secuencia del sistema, consulta el archivo [diagramas_sistema.md](diagramas_sistema.md)).*

---

## Plantilla
```markdown
# NNNN - Título corto

## Status
Accepted | Proposed | Superseded by NNNN

## Context
¿Qué problema o fuerza nos obliga a decidir algo?

## Decision
¿Qué decidimos hacer?

## Consequences
¿Qué se vuelve más fácil o más difícil con esta decisión?
```