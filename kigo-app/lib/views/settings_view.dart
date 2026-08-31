import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/membresia_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'companeros_casa_view.dart';
import 'join_centro_view.dart';
import 'privacy_policy_view.dart';

/// Vista de Ajustes rediseñada: estética moderna, estructurada por secciones,
/// perfil de usuario, gestión de fraccionamientos, compañeros de casa y preferencias.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('¿Cerrar sesión?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Tendrás que volver a ingresar con tu número de teléfono.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(120, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membresia = auth.centroActivo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            // 1. Tarjeta de Perfil de Residente
            _buildProfileCard(context, auth, isDark),
            const SizedBox(height: 24),

            // 2. Sección de Residencia y Fraccionamientos
            _buildSectionHeader('MI RESIDENCIA'),
            const SizedBox(height: 8),
            _buildResidenciaCard(context, auth, membresia, isDark),
            const SizedBox(height: 24),

            // 3. Sección de Preferencias
            _buildSectionHeader('PREFERENCIAS'),
            const SizedBox(height: 8),
            _buildPreferenciasCard(context, settings, isDark),
            const SizedBox(height: 24),

            // 4. Sección Legal e Información
            _buildSectionHeader('SOPORTE E INFORMACIÓN'),
            const SizedBox(height: 8),
            _buildInfoCard(context, isDark),
            const SizedBox(height: 32),

            // 5. Botón de Cerrar Sesión
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onPressed: () => _cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthViewModel auth, bool isDark) {
    final nombre = auth.nombreCompleto.isNotEmpty ? auth.nombreCompleto : 'Residente Kigo';
    final inicial = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : 'R';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryOrange, AppTheme.brandHover],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  auth.telefono,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Identidad Activa',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenciaCard(
    BuildContext context,
    AuthViewModel auth,
    MembresiaActual? membresia,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          if (membresia != null) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppTheme.primaryOrange, size: 22),
              ),
              title: Text(
                membresia.centroNombre,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              subtitle: Text(
                'Casa / Destino: ${membresia.casaDestino}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textGrey : AppTheme.textDimmed,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.people_alt_rounded, color: AppTheme.blue, size: 22),
              ),
              title: const Text(
                'Compañeros de casa',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Ver quiénes más están registrados en tu casa',
                style: TextStyle(fontSize: 12, color: AppTheme.textDimmed),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textDimmed),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanerosCasaView(tenantId: membresia.tenantId),
                  ),
                );
              },
            ),
            Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ],
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.surface2Dark : AppTheme.surface2Light),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.add_home_work_rounded, color: AppTheme.primaryOrange, size: 22),
            ),
            title: const Text(
              'Unirme a otro fraccionamiento',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Ingresa el código público de otro centro',
              style: TextStyle(fontSize: 12, color: AppTheme.textDimmed),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textDimmed),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinCentroView()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenciasCard(BuildContext context, SettingsViewModel settings, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (settings.themeMode == ThemeMode.dark ? AppTheme.amber : Colors.blueGrey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                settings.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: settings.themeMode == ThemeMode.dark ? AppTheme.amber : Colors.blueGrey,
                size: 22,
              ),
            ),
            title: const Text(
              'Modo Oscuro',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              settings.themeMode == ThemeMode.dark ? 'Activado' : 'Desactivado',
              style: const TextStyle(fontSize: 12, color: AppTheme.textDimmed),
            ),
            value: settings.themeMode == ThemeMode.dark,
            activeColor: AppTheme.primaryOrange,
            onChanged: (v) => settings.toggleTheme(v),
          ),
          Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.language_rounded, color: AppTheme.success, size: 22),
            ),
            title: const Text(
              'Idioma',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              settings.currentLocale.languageCode == 'es' ? 'Español' : 'English',
              style: const TextStyle(fontSize: 12, color: AppTheme.textDimmed),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.currentLocale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'es', child: Text('Español 🇲🇽')),
                  DropdownMenuItem(value: 'en', child: Text('English 🇺🇸')),
                ],
                onChanged: (v) {
                  if (v != null) settings.changeLanguage(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.textDimmed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.privacy_tip_rounded, color: AppTheme.textGrey, size: 22),
            ),
            title: Text(
              AppLocalizations.t(context, 'privacy_policy'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textDimmed),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
              );
            },
          ),
          Divider(height: 1, color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.textDimmed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.info_rounded, color: AppTheme.textGrey, size: 22),
            ),
            title: const Text(
              'Versión de Kigo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'v1.2.0 · AUTOnomIA Platform',
              style: TextStyle(fontSize: 12, color: AppTheme.textDimmed),
            ),
          ),
        ],
      ),
    );
  }
}
