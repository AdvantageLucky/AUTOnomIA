import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Por qué viene el visitante -- paso independiente y ordenable desde el
/// dashboard (KioskoConfig.motivoObligatorioVisitante + pasos_sin_invitacion),
/// igual que ROSTRO/INE/PLACA/DESTINO. Solo aplica a quien llega sin
/// invitación: un invitado ya trae el motivo desde la invitación que lo creó.
class MotivoView extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const MotivoView({super.key, this.totalSteps = 4, this.currentStep = 2});

  /// Motivos frecuentes como chips de un toque -- pedir el motivo por texto
  /// con teclado va contra el listón de "menos de 3 minutos, sin
  /// entrenamiento" del PRD. Genéricos a propósito (no "reparación de AC",
  /// etc.): el visitante no debería tener que pensar cuál aplica.
  static const _motivosFrecuentes = ['Paquete', 'Servicio', 'Visita', 'Proveedor'];

  Future<void> _escribirMotivoManual(BuildContext context) async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.kSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.t(context, 'cual_es_el_motivo'),
          style: TextStyle(color: context.kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.kTextPrimary),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.kBorder)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: KigoDesign.brand)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.t(context, 'cancelar_button'),
                style: TextStyle(color: context.kTextSecondary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.t(context, 'continue_button_text'),
                style: const TextStyle(color: KigoDesign.brand, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (context.mounted) Navigator.pop(context, motivo ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          appBar: AppBar(
            backgroundColor: context.kBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              // El último chip de la lista queda detrás del
              // micrófono/vigilante si se llega a scrollear hasta el fondo.
              padding: EdgeInsets.only(left: 42, right: 42, bottom: 40 + KigoDesign.clearanceBotonesFlotantes),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepIndicator(currentStep: currentStep, totalSteps: totalSteps),
                  const SizedBox(height: 42),
                  Text(
                    AppLocalizations.t(context, 'cual_es_el_motivo'),
                    style: TextStyle(color: context.kTextPrimary, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 32),
                  ..._motivosFrecuentes.map((m) => _buildCard(
                        context,
                        icono: Icons.info_outline_rounded,
                        titulo: m,
                        onTap: () => Navigator.pop(context, m),
                      )),
                  _buildCard(
                    context,
                    icono: Icons.more_horiz_rounded,
                    titulo: AppLocalizations.t(context, 'otro_destino_label'),
                    onTap: () => _escribirMotivoManual(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        BotonAsistenteFlotante(
          topDelBorde: 0,
          rightDelBorde: 16,
          onRespuestaLibre: (_) {},
          onCampoExtraido: (_) {},
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required IconData icono, required String titulo, required VoidCallback onTap}) {
    return Presionable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: context.kSurfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.kBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.kChipMarca,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: KigoDesign.brand, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(color: context.kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.kTextSecondary, size: 28),
          ],
        ),
      ),
    );
  }
}
