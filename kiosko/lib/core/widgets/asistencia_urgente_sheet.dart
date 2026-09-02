import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Hoja de asistencia urgente: información directa para llamar al
/// administrador, no un menú de opciones -- un visitante que no entiende
/// nada del flujo necesita el teléfono a la vista de inmediato, sin tocar
/// nada más. El teléfono viaja en la config cacheada localmente, así que se
/// muestra igual con o sin conexión del kiosko (quien llama es el celular
/// del visitante, por su propia red móvil).
///
/// El kiosko es una tablet fija sin chip ni app de teléfono real -- un botón
/// "llamar" ahí no hace nada útil. Por eso esto muestra un código QR
/// (`tel:<numero>`) para que el visitante lo escanee CON SU PROPIO celular y
/// el número en texto plano como respaldo si prefiere marcarlo a mano; no
/// hay ningún botón que intente lanzar una llamada desde el kiosko mismo.
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
            if (hayTelefono) ...[
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
                ),
                child: QrImageView(
                  data: 'tel:$telefonoContacto',
                  size: 180,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Escanéalo con tu celular para llamar',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.kTextTertiary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: context.kSurfaceCard,
                  borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
                  border: Border.all(color: context.kBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_rounded, color: context.kTextPrimary, size: 22),
                    const SizedBox(width: 12),
                    SelectableText(
                      telefonoContacto,
                      style: TextStyle(color: context.kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No hay teléfono de contacto configurado para este centro',
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
