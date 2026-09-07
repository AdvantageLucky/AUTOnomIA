import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escucha el esquema propio kigoapp://invitacion/<token> — ver
/// AndroidManifest.xml. Solo guarda el token; la invitación ya llegó
/// adjunta a la Persona por teléfono desde que se creó (CrearInvitacion),
/// así que no hay nada que "reclamar" — el token solo sirve para llevar al
/// usuario directo a verla.
///
/// Sin app instalada, la persona cae en la landing (/i/:token) y descarga
/// desde ahí; al abrir el link de nuevo ya con la app instalada, este
/// listener sí lo recibe (deep linking diferido no existe de gratis en
/// Android desde que Firebase Dynamic Links se dio de baja).
class DeepLinkServicio {
  static const _prefsPendingToken = 'kigo_pending_invitacion_token';

  StreamSubscription<Uri>? _sub;

  void iniciar() {
    final appLinks = AppLinks();
    _sub = appLinks.uriLinkStream.listen(_onUri, onError: (_) {});
    appLinks.getInitialLink().then((uri) {
      if (uri != null) _onUri(uri);
    });
  }

  Future<void> _onUri(Uri uri) async {
    if (uri.scheme != 'kigoapp' || uri.host != 'invitacion') return;
    final token = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsPendingToken, token);
  }

  /// Devuelve el token pendiente (si hay) y lo limpia — se consume una sola
  /// vez, al entrar al shell principal.
  static Future<String?> tomarTokenPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsPendingToken);
    if (token != null) await prefs.remove(_prefsPendingToken);
    return token;
  }

  void dispose() {
    _sub?.cancel();
  }
}
