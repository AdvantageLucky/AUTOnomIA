import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Hoja de asistencia urgente.
///
/// Con internet: pedir ayuda es una acción explícita, no un aviso que se
/// dispara solo con abrir la hoja -- el visitante ve un resumen de qué va a
/// pasar y toca "Solicitar asistencia" para que el backend avise al
/// dashboard/admin (SSE + correo). Antes se avisaba automáticamente apenas
/// se abría la hoja, sin que el visitante hiciera nada.
///
/// Sin internet no hay a quién avisar del lado del backend, así que se cae
/// directo al mismo respaldo de siempre: un código QR (`tel:<numero>`) para
/// que el visitante lo escanee CON SU PROPIO celular, más el número en
/// texto plano como respaldo. El kiosko es una tablet fija sin chip ni app
/// de teléfono real -- un botón "llamar" ahí no hace nada útil, por eso
/// nunca hay un botón que intente lanzar una llamada desde el kiosko mismo.
Future<void> mostrarAsistenciaUrgente(
  BuildContext context, {
  required String telefonoContacto,
  required bool offline,
  required VoidCallback onSolicitar,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AsistenciaUrgenteSheet(
      telefonoContacto: telefonoContacto,
      offline: offline,
      onSolicitar: onSolicitar,
    ),
  );
}

class _AsistenciaUrgenteSheet extends StatefulWidget {
  final String telefonoContacto;
  final bool offline;
  final VoidCallback onSolicitar;

  const _AsistenciaUrgenteSheet({
    required this.telefonoContacto,
    required this.offline,
    required this.onSolicitar,
  });

  @override
  State<_AsistenciaUrgenteSheet> createState() => _AsistenciaUrgenteSheetState();
}

class _AsistenciaUrgenteSheetState extends State<_AsistenciaUrgenteSheet> {
  bool _solicitando = false;
  bool _solicitada = false;

  Future<void> _solicitar() async {
    if (_solicitando || _solicitada) return;
    setState(() => _solicitando = true);
    // solicitarAsistenciaUrgente() ya falla en silencio (ver
    // KioskoServicio) -- aquí no hay nada más que hacer con el resultado,
    // el aviso es "mejor esfuerzo": si falla, el visitante ya vio la
    // confirmación en pantalla y no hay forma de que reintente a mano.
    widget.onSolicitar();
    if (!mounted) return;
    setState(() {
      _solicitando = false;
      _solicitada = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hayTelefono = widget.telefonoContacto.trim().isNotEmpty;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.kSurface1,
          borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        ),
        // La hoja no puede pasar de 9/16 de la pantalla: en una corta el
        // bloque de QR + teléfono no cabía y desbordaba por abajo. Scrollea
        // en vez de recortarse; en el panel entra completo y no se mueve.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _solicitada ? Icons.check_circle_rounded : Icons.support_agent_rounded,
                    color: _solicitada ? KigoDesign.success : KigoDesign.brand,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.t(context, 'asistencia_urgente_title'),
                      style: TextStyle(color: context.kTextPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _textoEstado(),
                style: TextStyle(color: context.kTextSecondary, fontSize: 15),
              ),
              const SizedBox(height: 20),
              if (widget.offline)
                _buildQrYTelefono(hayTelefono)
              else
                _buildSolicitarOnline(),
            ],
          ),
        ),
      ),
    );
  }

  String _textoEstado() {
    if (widget.offline) {
      return AppLocalizations.t(context, 'asistencia_urgente_offline_texto');
    }
    if (_solicitada) {
      return AppLocalizations.t(context, 'asistencia_urgente_ya_avisado');
    }
    return AppLocalizations.t(context, 'asistencia_urgente_se_notificara');
  }

  Widget _buildSolicitarOnline() {
    if (_solicitada) {
      return TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          AppLocalizations.t(context, 'asistencia_urgente_entendido'),
          style: TextStyle(color: context.kTextPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
    }
    return Material(
      color: KigoDesign.brand,
      borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        onTap: _solicitando ? null : _solicitar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_solicitando)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              else ...[
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                // Flexible: en una pantalla angosta la etiqueta desbordaba
                // el botón en vez de saltar de renglón.
                Flexible(
                  child: Text(
                    AppLocalizations.t(context, 'asistencia_urgente_solicitar'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrYTelefono(bool hayTelefono) {
    if (!hayTelefono) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          AppLocalizations.t(context, 'asistencia_urgente_sin_telefono'),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.kTextSecondary),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
          ),
          child: QrImageView(
            data: 'tel:${widget.telefonoContacto}',
            size: 180,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.t(context, 'asistencia_urgente_escanea_qr'),
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
              // El teléfono es dato del centro y puede venir con extensión:
              // sin holgura desbordaba la tarjeta en pantallas angostas.
              Flexible(
                child: SelectableText(
                  widget.telefonoContacto,
                  style: TextStyle(color: context.kTextPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
