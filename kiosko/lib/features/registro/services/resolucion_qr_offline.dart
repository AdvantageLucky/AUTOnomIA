/// Espejo offline de `ResolverEstadoQR` del backend
/// (backend/internal/domain/persona/resolucion_qr.go): miembro tiene
/// prioridad sobre invitado, y si no hay ninguno de los dos se rechaza —
/// antes de esto, `_verificarQrPersonaOffline` no tenía la rama "ninguno"
/// en absoluto (ver spec 2026-08-29-qr-ed25519-design.md).
enum EstadoQrOffline { miembro, invitado, ninguno }

class ResolucionQrOffline {
  final EstadoQrOffline estado;
  final String? nombre;
  final String? casaDestino;

  const ResolucionQrOffline(this.estado, {this.nombre, this.casaDestino});
}

ResolucionQrOffline resolverQrOffline({
  required Map<String, dynamic>? residenteMatch,
  required Map<String, dynamic>? invitacionMatch,
}) {
  if (residenteMatch != null) {
    return ResolucionQrOffline(
      EstadoQrOffline.miembro,
      nombre: '${residenteMatch['nombre']} ${residenteMatch['apellido_paterno']}',
      casaDestino: residenteMatch['casa_destino'] as String?,
    );
  }
  if (invitacionMatch != null) {
    return ResolucionQrOffline(
      EstadoQrOffline.invitado,
      nombre: invitacionMatch['titular'] as String?,
      casaDestino: invitacionMatch['casa_destino'] as String?,
    );
  }
  return const ResolucionQrOffline(EstadoQrOffline.ninguno);
}
