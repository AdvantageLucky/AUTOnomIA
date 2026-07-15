# ADR-0011: mobile_scanner para lectura de QR de invitaciones

**Estado:** Aceptado
**Fecha:** 2026-07-12
**Autores:** Alberto

## Contexto

El flujo de "Tengo invitación" requiere leer un código QR. El proyecto
ya usa el paquete camera para INE y rostro, pero ese paquete no incluye
detección de QR — requeriría implementar el decoder manualmente sobre
cada frame. Se evaluaron dos alternativas:

  a) qr_code_scanner — sin mantenimiento activo desde 2022.
  b) mobile_scanner — mantenido activamente, usa ML Kit internamente
     (que ya está en el proyecto), detección en tiempo real integrada.

## Decisión

Agregamos mobile_scanner: ^5.2.3. El QrScannerView usa MobileScanner
con DetectionSpeed.noDuplicates para evitar detecciones repetidas del
mismo código. Al detectar un QR se para el controlador y se navega con
pushReplacement a QrResultView para que el botón de regreso no regrese
al scanner activo.

El diálogo de consentimiento de cámara (consent_dialog.dart) se muestra
antes de inicializar el MobileScannerController, manteniendo consistencia
con los otros flujos de cámara de la app (ADR-0007).

## Consecuencias

Positivas:
- Integración lista para producción una vez que el backend valide el
  token del QR.
- Reutiliza el diálogo de consentimiento existente.
- Funciona sin conexión para la lectura; solo la validación necesita red.

Negativas / Trade-offs:
- Añade una segunda dependencia de cámara (mobile_scanner + camera)
  que no pueden usarse en la misma pantalla simultáneamente.
- El punto de validación del QR (onQrDetected en QrScannerView) está
  actualmente hardcodeado como éxito — requiere conexión al backend
  antes de ir a producción.