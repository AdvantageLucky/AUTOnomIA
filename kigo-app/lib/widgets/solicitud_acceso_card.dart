import 'package:flutter/material.dart';
import '../models/visita_pendiente_model.dart';
import '../theme/app_theme.dart';
import 'visita_foto.dart';

/// Solicitud de acceso con la foto que tomó el kiosko como protagonista: el
/// residente decide mirando la cara, así que la foto manda sobre el texto.
class SolicitudAccesoCard extends StatelessWidget {
  const SolicitudAccesoCard({
    super.key,
    required this.visita,
    required this.onAprobar,
    required this.onRechazar,
  });

  final VisitaPendienteModel visita;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical, no apaisado: la captura del kiosko es un retrato, y con
          // un marco horizontal el BoxFit.cover recorta justo la cabeza.
          AspectRatio(
            aspectRatio: 3 / 4,
            child: VisitaFoto(url: visita.fotoRostroUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visita.titular,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visita.casaDestino,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.textGrey : const Color(0xFF8A8BA8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Mismo orden que la pantalla anterior (aprobar a la izquierda):
                // moverlos de lado invita a rechazar por inercia una visita
                // que se queria aprobar.
                _BotonRespuesta(
                  icono: Icons.check_rounded,
                  color: AppTheme.success,
                  tooltip: 'Aprobar',
                  onPressed: onAprobar,
                ),
                const SizedBox(width: 12),
                _BotonRespuesta(
                  icono: Icons.close_rounded,
                  color: AppTheme.error,
                  tooltip: 'Rechazar',
                  onPressed: onRechazar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRespuesta extends StatelessWidget {
  const _BotonRespuesta({
    required this.icono,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icono;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icono, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
