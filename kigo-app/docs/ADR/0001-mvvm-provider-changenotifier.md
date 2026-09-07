# ADR-0001: MVVM con el paquete `provider` para manejo de estado

**Estado:** Aceptado
**Fecha:** 2026-07-12
**Autores:** (completar)

## Contexto

kigo-app coordina varios flujos con estado propio que varias vistas necesitan leer a la vez: sesión
del usuario, membresías activas, invitaciones, solicitudes pendientes, historial de visitas. El
kiosko (ver ADR-0001 de kiosko) resolvió un problema similar con `ChangeNotifier` puro y
`addListener`/`removeListener` manual, sin ninguna librería externa de estado.

## Decisión

kigo-app usa el mismo patrón MVVM con `ChangeNotifier`, pero apoyado en el paquete `provider`
(`^6.1.2`) en vez de `addListener` manual. `main.dart` registra un `MultiProvider` con un
`ChangeNotifierProvider` por ViewModel (`AuthViewModel`, `SettingsViewModel`,
`InvitationViewModel`, `PendingVisitsViewModel`, `VisitHistoryViewModel`,
`CompanerosCasaViewModel`, `IdentidadesConfianzaViewModel`) a nivel raíz de la app. Las vistas
consumen con `context.watch<T>()` / `context.read<T>()` en vez de un `Consumer` explícito o
suscripción manual.

`AuthViewModel` se registra con `lazy: false` porque su constructor dispara
`_checkSession()` — la app necesita saber si ya hay una sesión válida antes de que `SplashView`
decida a qué ruta navegar; el resto de los ViewModels sí son perezosos, se instancian hasta que
la primera vista que los usa monta.

## Consecuencias

Positivas:
- Sin gestor de estado más pesado (Bloc, Riverpod): mismo criterio de simplicidad que el kiosko.
- `context.watch`/`context.read` es más corto que `addListener`/`removeListener` manual en cada
  `StatefulWidget`, a costa de una dependencia adicional (`provider`) que el kiosko no tiene.
- Registrar todos los ViewModels en la raíz simplifica el acceso desde cualquier vista, sin pasar
  referencias explícitas por el árbol de widgets.

Negativas / Trade-offs:
- Todos los ViewModels viven en memoria durante toda la vida de la app (los perezosos se crean al
  primer uso pero nunca se destruyen hasta cerrar la app), no solo mientras su pantalla está
  visible.
- `AuthViewModel` con `lazy: false` corre su lógica de red (`_checkSession`) en cuanto arranca
  `main()`, antes de que cualquier vista exista — cualquier cambio a ese constructor debe recordar
  que se ejecuta sin `BuildContext` disponible.
