class AppConstants {
  static const String appName = 'Kigo';

  // ─── CONFIGURACIÓN DEL SERVIDOR ──────────────────────────────────────────
  // Cambia serverHost a la IP LAN de la máquina donde corre el backend.
  // Ejemplo: '192.168.1.100'  (obtén tu IP con: ip addr | grep 192)
  // ─────────────────────────────────────────────────────────────────────────
  static const String serverHost = 'localhost';
  static const String apiBaseUrl = 'http://$serverHost:8000/api/v1';

  // Única clave persistida — todo lo demás (perfil, membresía) se
  // recarga del backend al restaurar sesión, nunca se cachea localmente.
  static const String prefsJwt = 'kigo_jwt';

  // Sobrevive temporalmente: la usa `viewmodels/invitation_viewmodel.dart`
  // (flujo viejo de Residente). El brief de Task 2 la daba por no usada,
  // pero ese archivo se elimina hasta Task 5 — se retira de aquí en ese
  // mismo commit.
  static const String prefsTokenCache = 'kigo_token_cache';
}
