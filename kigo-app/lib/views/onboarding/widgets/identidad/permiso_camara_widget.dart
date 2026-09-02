import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';

/// Pantalla de error cuando falta el permiso de cámara -- reemplaza el
/// texto genérico "no se pudo iniciar la cámara" (que dejaba al usuario sin
/// forma de arreglarlo) por una acción concreta según el motivo real.
class PermisoCamaraDenegado extends StatelessWidget {
  final bool permanente;
  final VoidCallback onReintentar;

  const PermisoCamaraDenegado({
    super.key,
    required this.permanente,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, color: AppTheme.textGrey, size: 40),
          const SizedBox(height: 16),
          Text(
            permanente
                ? AppLocalizations.t(context, 'camara_permiso_ajustes')
                : AppLocalizations.t(context, 'camara_permiso_necesitamos'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: permanente ? openAppSettings : onReintentar,
            child: Text(permanente
                ? AppLocalizations.t(context, 'camara_permiso_abrir_ajustes')
                : AppLocalizations.t(context, 'camara_permiso_dar_permiso')),
          ),
        ],
      ),
    );
  }
}
