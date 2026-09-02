import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Hoja de asistencia urgente: información directa para llamar al
/// administrador, no un menú de opciones -- un visitante que no entiende
/// nada del flujo necesita el teléfono a la vista de inmediato, sin tocar
/// nada más. El teléfono viaja en la config cacheada localmente, así que se
/// muestra igual con o sin conexión del kiosko (quien llama es el celular
/// del visitante, por su propia red móvil).
///
/// Además de mostrar el teléfono, dispara [onSolicitar] (si no es offline)
/// para que el backend avise al dashboard/admin -- es el mismo tap el que
/// hace ambas cosas, no hay un botón separado para "avisar".
Future<void> mostrarAsistenciaUrgente(
  BuildContext context, {
  required String telefonoContacto,
  required bool offline,
  required VoidCallback onSolicitar,
}) {
  if (!offline) onSolicitar();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AsistenciaUrgenteSheet(telefonoContacto: telefonoContacto, offline: offline),
  );
}

class _AsistenciaUrgenteSheet extends StatelessWidget {
  final String telefonoContacto;
  final bool offline;

  const _AsistenciaUrgenteSheet({required this.telefonoContacto, required this.offline});

  Future<void> _llamar(BuildContext context) async {
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.kSurface1,
          borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: KigoDesign.brand, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Asistencia urgente',
                    style: TextStyle(color: context.kTextPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              offline
                  ? 'Sin conexión: llama directamente, el administrador no recibirá el aviso automático.'
                  : 'Ya se avisó al administrador. Si es urgente, llama directamente:',
              style: TextStyle(color: context.kTextSecondary, fontSize: 15),
            ),
            const SizedBox(height: 20),
            if (hayTelefono)
              Material(
                color: KigoDesign.brand,
                borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
                  onTap: () => _llamar(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.call_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          telefonoContacto,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No hay teléfono de contacto configurado para este kiosko',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.kTextSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
