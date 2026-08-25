# ADR-0025: El kiosko arranca en el escáner QR, no en Visitante/Residente

**Estado:** Aceptado
**Fecha:** 2026-08-18

## Contexto

El kiosko arrancaba en `WelcomeView`, con dos botones (Visitante/Residente) como
punto de entrada. Con la app Kigo ya en producción, cualquier visitante o
residente que la trae consigo llega con un QR personal firmado
(`persona_id:firma`, ver ADR de identidad Persona) que ya lo identifica por
completo — obligarlo a navegar dos pantallas y elegir una categoría antes de
poder escanear ese QR es fricción innecesaria, justo cuando el objetivo es
"acceso ultra rápido" para quien ya lo tiene.

## Decisión

**El escáner QR es la pantalla de entrada del kiosko — reemplaza a
`WelcomeView` como `home` en `main.dart`.**

1. `QrScannerView` gana un modo "pantalla principal": arranca a escanear solo
   apenas se acepta el consentimiento de cámara, sin el paso intermedio de
   "toca para escanear" que sí tiene sentido en un flujo secundario.
2. Detecta ambos formatos en el mismo lugar: QR personal (`persona_id:firma`,
   contiene `:`) y token de invitación de siempre (hex sin `:`) — un solo
   punto de entrada para los dos mecanismos.
3. Botón "No tengo la app Kigo o código QR" es la única salida — lleva al
   `WelcomeView` de siempre, sin tocarlo ni simplificarlo. El flujo manual
   completo (INE-cara-motivo-destino) queda intacto como respaldo.
4. Las pantallas de resultado (`PersonaQrResultView`, `QrResultView`) regresan
   solas al escáner tras ~5s en estado terminal — el kiosko procesa visitantes
   en fila, nadie debería tener que tocar nada para "reiniciar" para el
   siguiente.
5. Cada reinicio monta una instancia nueva de `QrScannerView`, pidiendo
   consentimiento de cámara de nuevo — cada persona da su propio
   consentimiento, no se reutiliza el de quien pasó antes.

Se descartó dejar el QR como una opción más dentro de `VisitorTypeView`
(pantalla intermedia "Visitante"): con el QR ya al frente, esa pantalla dejó
de tener un propósito — sus dos opciones ("Escanear invitación" / "No tengo
invitación") colapsaron a una sola, así que se eliminó junto con el modo no
principal de `QrScannerView` que la alimentaba.

## Consecuencias

- El camino QR es, a propósito, minimalista: sin el header grande
  "Kigo / SELF CHECK-IN" repetido en cada pantalla, reemplazado por un
  wordmark de esquina — el veredicto (concedido/denegado) es lo único que
  compite por atención.
- Un anillo continuo que respira mientras escanea y se cierra al detectar
  reemplaza el marco de esquinas + ícono con borde de antes — mismo lenguaje
  visual entre escaneo y resultado.
- `VisitorTypeView` y `VisitorTypeViewModel` se borraron por completo — sin
  llamadores, dejarlos habría sido código muerto.
- El flujo manual (INE-cara-motivo-destino) sigue siendo el único camino para
  quien no trae ni app ni invitación — este ADR no lo modifica.
