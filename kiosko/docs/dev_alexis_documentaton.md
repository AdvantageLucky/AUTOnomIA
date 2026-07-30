# 🛠️ Guía de Desarrollo - Rama `dev/alexis`

Documentación de apoyo para el despliegue, pruebas y control de versiones del frontend en Flutter para el proyecto de Kiosko **Kigo**.

---

## 🔄 Flujo de Trabajo y Pruebas

Sigue estos comandos en tu terminal para sincronizar el repositorio y probar los últimos cambios de la interfaz, incluyendo el módulo de interacción por voz y animaciones.

### 1. ACTUALIZAR REPO LOCAL
Asegúrate de traer los últimos cambios del servidor antes de comenzar:

```bash
git pull origin main
```

### CAMBIAR A ESTA RAMA
```bash
    git checkout dev/alexis
```
### ACTUALIZAR REPOS
```bash
    flutter pub get
```
### PROBAR RAMA
```bash
    flutter run
```
### REGRESAR AL MAIN
```bash
    git checkout origin/main
```