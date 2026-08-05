# ADR-0014: Bloqueo de modo kiosko con Lock Task Mode y salida por PIN de operador

**Estado:** Aceptado
**Fecha:** 2026-08-04
**Autores:** Alberto Luna y Jesus Mendoza 

## Contexto

La app ya activaba modo inmersivo (`SystemUiMode.immersiveSticky` en
`main.dart`) desde el inicio, pero eso solo oculta las barras del
sistema — no impide que cualquiera use los gestos de Home o Recientes
para salir de la app, ni restringe notificaciones o Quick Settings. Un
kiosko de auto-registro sin operador presente necesita quedarse fijo en
la app, con una vía de escape reservada solo para el operador. El
problema se hizo evidente al probar la app en un teléfono físico
simulando el kiosko de la caseta: cualquiera podía salir con el botón
Home.

## Decisión

### Lock Task Mode nativo, expuesto por MethodChannel

Se usa Android Lock Task Mode ("pantalla fijada"/screen pinning) vía
`startLockTask()`/`stopLockTask()` en `MainActivity.kt`, sin necesitar
modo Device Owner (que requiere aprovisionamiento especial y no aplica
para probar en un teléfono cualquiera). Se expone a Flutter con un
`MethodChannel` (`com.example.kigo_kiosco/kiosk_mode`, único método
`exitKioskMode`).

`onResume()` re-arma el bloqueo automáticamente cada vez que la
actividad vuelve a primer plano, controlado por un flag
`kioskLockEnabled` que solo se pone en `false` cuando el operador sale
con el PIN correcto. Así el bloqueo se auto-repara si el sistema lo
soltó por cualquier motivo, pero no se vuelve a armar inmediatamente
después de una salida ya autorizada.

El modo inmersivo (`immersiveSticky`) también se reaplica en cada
resume: `KigoApp` pasó de `StatelessWidget` a `StatefulWidget` con
`WidgetsBindingObserver`, porque Android suele soltar el modo inmersivo
al volver de segundo plano.

### Gesto oculto + PIN enmascarado, no un botón visible

Mantener presionada la pantalla de bienvenida 5 segundos abre
`OperatorExitPinView`. Se implementó con un `Timer` manual en
`onTapDown`/cancelado en `onTapUp`/`onTapCancel`, no con el
`onLongPress` por defecto de Flutter (que dispara a los ~500ms) — el
gesto se puso sobre toda la pantalla, no sobre un botón dedicado, para
que no sea descubrible por un visitante.

El PIN se muestra como puntos enmascarados, a diferencia del PIN de
residente de ADR-0009 (que sí muestra los dígitos, porque no es un
secreto, es solo un identificador). Aquí sí es un gate de seguridad.

### PIN hardcodeado, sin integración con el backend todavía

El PIN correcto (`_pinOperador = '2026'` en `OperatorExitViewModel`)
está fijo en el cliente. No hay todavía relación con `KioskoConfig` del
backend para hacerlo configurable por kiosko desde el dashboard.

## Consecuencias

Positivas:
- Bloquea Home/Recientes y restringe notificaciones/Quick Settings sin
  necesitar aprovisionamiento como Device Owner.
- Se auto-repara solo en cada `onResume`, sin depender de que el lado
  Flutter recuerde reactivarlo.
- El gesto de salida no es descubrible por un visitante casual, y el
  PIN queda enmascarado por ser un secreto real (a diferencia del PIN
  de residente).

Negativas / Trade-offs:
- Android siempre permite una salida de emergencia a nivel de sistema
  (mantener Atrás + Recientes, o deslizar-y-sostener en navegación por
  gestos) que ninguna app normal puede bloquear sin ser Device Owner —
  es una garantía de accesibilidad de Android, no un bug de esta
  implementación.
- El PIN de operador está hardcodeado en el cliente — cualquiera con
  acceso al código fuente o al APK descompilado puede leerlo. Es
  fricción deliberada contra un visitante casual, no una barrera de
  seguridad real.
- En fabricantes con Android muy personalizado (MIUI, One UI antiguos)
  puede requerir habilitar manualmente "Fijar app" en Ajustes antes de
  que `startLockTask()` funcione al 100%.
- El PIN es el mismo para todos los kioskos; no hay aún un PIN por
  kiosko ni gestión desde el dashboard admin.
