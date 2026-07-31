class AppConstants {
  static const String appName = 'Kigo Residente';

  // ─── CONFIGURACIÓN DEL SERVIDOR ──────────────────────────────────────────
  // Cambia serverHost a la IP LAN de la máquina donde corre el backend.
  // Ejemplo: '192.168.1.100'  (obtén tu IP con: ip addr | grep 192)
  // ─────────────────────────────────────────────────────────────────────────
  static const String serverHost = 'localhost';
  static const String apiBaseUrl = 'http://$serverHost:8000/api/v1';

  // Claves para SharedPreferences
  static const String prefsJwt = 'kigo_jwt';
  static const String prefsKioskoId = 'kigo_kiosko_id';
  static const String prefsCasaDestino = 'kigo_casa_destino';
  static const String prefsDestinoId = 'kigo_destino_id';
  static const String prefsNombre = 'kigo_nombre';
  static const String prefsTokenCache = 'kigo_token_cache';
}
