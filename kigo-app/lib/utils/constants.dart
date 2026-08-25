class AppConstants {
  static const String appName = 'Kigo';

  // ─── CONFIGURACIÓN DEL SERVIDOR ──────────────────────────────────────────
  // Cambia serverHost a la IP LAN de la máquina donde corre el backend.
  // Ejemplo: '192.168.1.100'  (obtén tu IP con: ip addr | grep 192)
  // ─────────────────────────────────────────────────────────────────────────
  static const String serverHost = 'localhost';
  static const String apiBaseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1/';

  // Única clave persistida — todo lo demás (perfil, membresía) se
  // recarga del backend al restaurar sesión, nunca se cachea localmente.
  static const String prefsJwt = 'kigo_jwt';
}
