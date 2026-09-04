import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Hoja de ayuda: llamar al administrador y, si se pasa [onFaq], ver
/// preguntas frecuentes. Funciona sin internet en el kiosko -- el que llama
/// es el celular del visitante, por su propia red móvil, no el wifi del
/// kiosko. Vive aparte de BotonAsistente porque también hay que mostrarla
/// desde el estado offline, que ya tenía su propio tap.
Future<void> mostrarMenuAyuda(
  BuildContext context, {
  required String telefonoContacto,
  VoidCallback? onFaq,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MenuAyudaSheet(telefonoContacto: telefonoContacto, onFaq: onFaq),
  );
}

class _MenuAyudaSheet extends StatelessWidget {
  final String telefonoContacto;
  final VoidCallback? onFaq;

  const _MenuAyudaSheet({required this.telefonoContacto, this.onFaq});

  Future<void> _llamar(BuildContext context) async {
    Navigator.pop(context);
    final uri = Uri(scheme: 'tel', path: telefonoContacto);
    try {
      await launchUrl(uri);
    } catch (_) {
      // Sin app de teléfono disponible (poco probable en un Android real) --
      // no hay nada más que hacer, no tronar la pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    final hayTelefono = telefonoContacto.trim().isNotEmpty;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        // Material y no una `BoxDecoration`: la hoja se abre con fondo
        // transparente, así que los ListTile no encontraban superficie
        // donde pintar y el framework avisaba en cada apertura ("background
        // color or ink splashes may be invisible").
        child: Material(
          color: context.kSurface1,
          borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hayTelefono)
                  ListTile(
                    leading: const Icon(Icons.call_rounded, color: KigoDesign.brand),
                    title: Text(AppLocalizations.t(context, 'menu_ayuda_llamar_admin'), style: TextStyle(color: context.kTextPrimary)),
                    subtitle: Text(telefonoContacto, style: TextStyle(color: context.kTextSecondary)),
                    onTap: () => _llamar(context),
                  ),
                if (onFaq != null)
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: KigoDesign.brand),
                    title: Text(AppLocalizations.t(context, 'menu_ayuda_preguntas_frecuentes'), style: TextStyle(color: context.kTextPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      onFaq!();
                    },
                  ),
                if (!hayTelefono && onFaq == null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppLocalizations.t(context, 'menu_ayuda_sin_opciones'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.kTextSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
