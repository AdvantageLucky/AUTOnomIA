class AppConstants {
  static const String appName = 'Kigo';

  // ─── CONFIGURACIÓN DEL SERVIDOR ──────────────────────────────────────────
  // Sin / al final: todas las llamadas en ApiService pasan el path con /
  // inicial (ej. '/personas/me/qr') — con trailing slash aquí, la
  // concatenación produce // y el backend responde 404 (verificado en vivo).
  // ─────────────────────────────────────────────────────────────────────────
  static const String serverHost = 'localhost';
  static const String apiBaseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1';

  // Única clave persistida — todo lo demás (perfil, membresía) se
  // recarga del backend al restaurar sesión, nunca se cachea localmente.
  static const String prefsJwt = 'kigo_jwt';
}
