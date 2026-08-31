import 'package:kigo_user/services/api_service.dart';

/// Cliente del backend para Kigo Verify — la app nunca habla directo con
/// Kigo (la API key vive solo en el backend). Ver
/// docs/superpowers/specs/2026-08-29-kigo-verify-kigo-app-design.md.
class KigoVerifyServicio {
  /// [redirectUrl] es el centinela que el backend le pidio a Kigo: viene en
  /// la respuesta en vez de estar hardcodeado aqui, porque tenerlo escrito en
  /// las dos puntas dejaba que se separaran en silencio y el WebView no
  /// cerraba nunca. Si el backend es viejo y no lo manda, se cae al valor
  /// historico.
  Future<({String enrollmentId, String enrollmentUrl, String redirectUrl})> iniciar() async {
    final data = await ApiService().post('/personas/me/kigo-verify/iniciar', {}, auth: true);
    return (
      enrollmentId: data['enrollment_id'] as String,
      enrollmentUrl: data['enrollment_url'] as String,
      redirectUrl: data['redirect_url'] as String? ?? 'https://autonomia.local/kigo-verify-listo',
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
