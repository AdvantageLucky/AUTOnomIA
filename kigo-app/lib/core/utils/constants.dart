class AppConstants {
  static const String appName = 'Kigo';

  // ─── CONFIGURACIÓN DEL SERVIDOR ──────────────────────────────────────────
  // Sin / al final: todas las llamadas en ApiService pasan el path con /
  // inicial (ej. '/personas/me/qr') — con trailing slash aquí, la
  // concatenación produce // y el backend responde 404 (verificado en vivo).
  // ─────────────────────────────────────────────────────────────────────────
  static const String serverHost = 'localhost';
  static const String apiBaseUrl = 'https://homelab.tail8dc7f1.ts.net/api/v1';

  // El perfil y las membresías se recargan del backend al restaurar sesión,
  // nunca se cachean localmente -- salvo cuál centro quedó seleccionado
  // (prefsCentroActivoId), que sí necesita sobrevivir entre sesiones.
  static const String prefsJwt = 'kigo_jwt';
  static const String prefsCentroActivoId = 'kigo_centro_activo_id';

  /// Origen del backend, sin el prefijo /api/v1 — de ahí cuelga /uploads.
  static String get serverOrigin {
    final u = Uri.parse(apiBaseUrl);
    return Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null)
        .toString();
  }

  /// Reancla una URL de archivo del backend al origen que usa esta app.
  ///
  /// El backend arma `foto_rostro_url` con el Host de la petición que subió la
  /// foto, y quien la sube es el kiosko: si el kiosko habla con el backend por
  /// la IP de la LAN, la URL guardada apunta a un host que el teléfono del
  /// residente no alcanza y la imagen queda en blanco. La ruta sí es válida
  /// —los archivos se sirven en /uploads del mismo servidor—, así que se
  /// conserva la ruta y se cambia el origen.
  static String mediaUrl(String raw) {
    if (raw.isEmpty) return '';
    final u = Uri.tryParse(raw);
    if (u == null) return '';
    return '$serverOrigin${u.path}';
  }
}
