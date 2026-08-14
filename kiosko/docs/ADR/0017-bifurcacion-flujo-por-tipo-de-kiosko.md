# ADR-0017: Bifurcación del flujo de registro por tipo de kiosko

**Estado:** Aceptado
**Fecha:** 2026-08-13
**Relacionado:** ADR-0008 (bifurcación por tipo de usuario), ADR-0005 (flujo de 3 pasos), backend ADR-0022, ADR-0023 y ADR-0024

## Contexto

El kiosko estaba pensado para un acceso peatonal: `TouchRegisterView` corre dos
pasos fijos (INE y rostro), luego casa destino y resumen. El backend ya
distinguía kioskos `PEATONAL` de `VEHICULAR` y ya guardaba `placa` y
`foto_placa_url` en cada visita, pero la app nunca capturaba ninguno de los dos:
`UserRegistrationModel.placa` existía sin que nadie lo llenara y
`_enviarRegistro` mandaba el campo siempre vacío, sin adjuntar `foto_placa`.
Encender `foto_placa_visitante` desde el dashboard hacía fallar todos los
registros con un 400.

Hacía falta un flujo vehicular que conviviera con el peatonal sin mezclarse. Las
opciones eran:

1. **Un segundo APK / flavor** para casetas vehiculares.
2. **Un solo flujo parametrizado** que agregara el paso de placa con un `if`.
3. **Un solo APK con dos flujos separados**, elegidos según el tipo que manda el
   backend.

## Decisión

**Opción 3.** El tipo llega en la config del kiosko (backend ADR-0022) y decide
qué flujo se monta; el código de cada flujo vive en su propia carpeta de feature.

1. **`features/registro_vehicular/` es hermana de `features/registro/`.** Tiene
   su propio `VehicularRegisterViewModel`, su vista, su scanner de placa y sus
   copys. Los servicios pesados se comparten tal cual: `DetectorServicio` (OCR de
   INE), `FaceDetectorServicio` y `KioskoServicio`. Se descartó el flujo único
   con `if` (opción 2) porque los dos contextos divergen —en el vehicular el
   visitante está dentro de un coche, con fila detrás— y esa divergencia iba a
   crecer; se descartó el flavor (opción 1) porque obligaría a reinstalar para
   cambiar el tipo de una caseta.

2. **`core/routing/RegistroRouter` es el único lugar que decide.** Las vistas de
   bienvenida no saben de tipos: preguntan al router qué flujo montar. Agregar un
   tercer tipo de acceso es tocar un archivo.

3. **El tipo decide el flujo; la config decide las capturas opcionales.** El
   `VehicularRegisterViewModel` arma su lista de pasos en el constructor en vez
   de tenerlos fijos. Pedir una foto que el backend no exige alarga la fila;
   omitir una que sí exige hace que el registro se rechace al final, después de
   que el visitante ya hizo todo el trabajo.

   **Sin invitación el flujo es placa → rostro → destino: no se pide INE.** El
   conductor no baja del coche, y la matrícula es lo que identifica la visita en
   la bitácora (backend ADR-0024). Por eso el paso de placa va primero y no es
   opcional; el rostro depende de `fotoRostroVisitante`. Con invitación mandan
   los toggles de invitado (`ineObligatorioInvitado`, `fotoRostroInvitado`,
   `fotoPlacaInvitado`), porque ahí el QR ya identifica a quien llega.

4. **El OCR de placa nunca es la única vía.** `PlacaDetectorServicio` usa el mismo
   MLKit que la INE con máscaras posicionales de placa mexicana (`AAA999A`,
   `AAA9999`, `999AAA`, `AA99999`) y corrección O↔0 / I↔1 / S↔5 según lo que la
   máscara espera en cada posición. Pero la placa se fotografía en exteriores
   —sol, lluvia, mica sucia, ángulo— y falla mucho más seguido que una credencial
   sostenida frente a la cámara. Tras cada captura se abre `ConfirmarPlacaView`,
   que deja corregir o escribir la placa a mano. Una lectura fallida no obliga a
   repetir la foto.

5. **La corrección de la placa usa teclado propio, no el del sistema.** La app
   corre en `SystemUiMode.immersiveSticky` y re-aplica el modo inmersivo en cada
   resume (`main.dart`). Al abrir el IME de Android, el teclado muestra las
   barras de sistema, la app las vuelve a ocultar y el ciclo de viewport metrics
   entre ambos cuelga el hilo principal: ANR reproducible en cuanto el visitante
   toca el campo. Sumado a que en modo kiosko con lock task (ADR-0014) el
   teclado del sistema es una superficie que no queremos exponer, la respuesta
   es la misma que ya usaban el PIN de residente, el PIN de operador y el código
   de activación: un teclado dibujado en pantalla. `ConfirmarPlacaView` es una
   vista completa con distribución QWERTY más fila numérica.

   **Consecuencia para quien siga trabajando aquí: esta app no puede usar
   `TextField`.** No hay ninguno en `lib/`, y agregarlo reintroduce el ANR.

6. **El invitado que debe dejar capturas pasa por el mismo flujo.** Si la config
   pide INE, rostro o placa a los invitados, al escanear el QR se valida el token
   (sin consumirlo), se piden las capturas y hasta el final se consume la
   invitación con las fotos adjuntas. El invitado no elige casa destino: viene en
   su invitación.

## Consecuencias

- El mismo APK atiende ambos tipos de caseta y se reconfigura solo cuando el
  admin cambia el tipo desde el dashboard, sin reinstalar.
- `CasaDestinoView` y `ResumenSolicitudView` reciben `totalSteps` como parámetro
  porque el número de pasos ya no es fijo en 4.
- Los dos flujos comparten los servicios pero no las vistas: un cambio de copy o
  de layout en el peatonal no toca al vehicular y viceversa. El costo es que
  arreglos genuinamente comunes hay que aplicarlos dos veces; se acepta a
  cambio de que cada flujo pueda especializarse.
- `VehicularRegisterView` también se usa en kioskos peatonales cuando hay que
  pedirle capturas a un invitado, porque es el wizard que se arma desde la
  config. El nombre queda un poco estrecho respecto de lo que hace.
- Sigue faltando una animación guía para el paso de placa, equivalente a
  `IneApproachAnimation`; hoy hay una guía estática con la instrucción.
