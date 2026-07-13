# Changelog / Historial de Cambios

Este archivo documenta el historial de cambios, mejoras y lanzamientos del backend **AUTOnomIA**, organizado por versiones y fechas correspondientes

## Unrealeased
- Templates Admin: Template para chequeo de estadisticas generales siendo admin de condominio (de distintos accesos que se tengan)


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
