import 'package:kigo_user/services/api_service.dart';

/// Cliente del backend para Kigo Verify — la app nunca habla directo con
/// Kigo (la API key vive solo en el backend). Ver
/// docs/superpowers/specs/2026-08-29-kigo-verify-kigo-app-design.md.
class KigoVerifyServicio {
  Future<({String enrollmentId, String enrollmentUrl})> iniciar() async {
    final data = await ApiService().post('/personas/me/kigo-verify/iniciar', {}, auth: true);
    return (
      enrollmentId: data['enrollment_id'] as String,
      enrollmentUrl: data['enrollment_url'] as String,
    );
  }

  Future<({String status, String? fotoUrl})> consultarEstado(String enrollmentId) async {
    final data = await ApiService().get('/personas/me/kigo-verify/estado?enrollment_id=$enrollmentId');
    return (
      status: data['status'] as String,
      fotoUrl: data['foto_url'] as String?,
    );
  }
}
