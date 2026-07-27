# 🤝 Lineamientos de Colaboración

¡Bienvenido al equipo de desarrollo de **AUTOnomIA**! Este documento establece las convenciones de trabajo para mantener la calidad del código, un historial de versiones limpio y facilitar la integración continua dentro de nuestro monorepo.

## 🗣️ Idioma y Comunicación
*   **Documentación y Revisión:** Todos los mensajes de commit, descripciones de Pull Requests (PRs), issues y discusiones técnicas se redactarán en español.
*   **Código Fuente:** Para alinearnos con los estándares de la industria, la nomenclatura de variables, funciones, clases y comentarios internos del código debe escribirse en **inglés**.

## 🌿 Gestión de Ramas (Branches)
Nuestra rama principal de desarrollo es `dev`. **Queda estrictamente prohibido realizar *pushes* directos a `dev` o `main`.**

Para implementar nuevas características, correcciones de errores o tareas de mantenimiento, se debe crear una nueva rama a partir de `dev` siguiendo esta nomenclatura:
*   `feature/nombre-de-la-funcionalidad` (Ej: `feature/login-residente`)
*   `fix/descripcion-del-error` (Ej: `fix/crash-camara-kiosko`)
*   `chore/tarea-de-mantenimiento` (Ej: `chore/actualizar-dependencias`)

## 📝 Convenciones de Commits
Utilizamos la metodología *Conventional Commits* para estandarizar el historial del repositorio. Los mensajes deben ser concisos y descriptivos:
*   `feat: agrega el escaneo de código QR en aplicación residente`
*   `fix: corrige error de conexión con la base de datos PostgreSQL`
*   `chore: actualiza el archivo .gitignore del entorno raíz`
*   `docs: actualiza el diagrama de arquitectura del sistema`

## 🔄 Proceso de Pull Requests (PRs)
1. Antes de abrir un PR, asegúrate de integrar los últimos cambios realizando un `git pull origin dev` en tu entorno local para resolver posibles conflictos.
2. Abre el PR documentando claramente el propósito de los cambios y qué problema resuelven.
3. El código debe ser revisado por al menos un miembro del equipo antes de ser fusionado (*merged*).
4. El proceso de *Code Review* es una herramienta de calidad; los comentarios deben ser constructivos y enfocados en la arquitectura, optimización y seguridad.

## 🧑‍💻 Liderazgo y Soporte Técnico
Si existen dudas sobre la arquitectura general, problemas de integración entre Go y Flutter, o bloqueos con el entorno de despliegue, el equipo debe escalar el problema para su revisión conjunta.