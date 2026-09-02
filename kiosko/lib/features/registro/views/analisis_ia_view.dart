import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/score_ia_model.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';

/// Detalle completo del análisis de IA de una visita -- SOLO detrás del PIN
/// de operador (ver pin_operador_sheet.dart). A diferencia del sello que ve
/// el visitante (confianza + nivel, nada más), aquí sí van los factores
/// negativos/faltantes y las recomendaciones: es lo que el PRD del reto
/// llama "una vista de consulta para el vigilante", con la evidencia y el
/// razonamiento a la mano -- nunca se le muestra a quien está siendo
/// evaluado.
class AnalisisIaView extends StatelessWidget {
  final ScoreIaModel score;
  final String? resumen;

  const AnalisisIaView({super.key, required this.score, this.resumen});

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (score.nivelConfianza) {
      'alta' => (const Color(0xFF4CAF50), 'Confianza alta'),
      'media' => (KigoDesign.brand, 'Confianza media'),
      _ => (const Color(0xFFE53935), 'Confianza baja'),
    };

    return Scaffold(
      backgroundColor: context.kBg,
      appBar: AppBar(
        backgroundColor: context.kBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Análisis de IA', style: TextStyle(color: context.kTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            if (!score.generadoPorIA)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.kSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: context.kTextSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Análisis automático -- el asistente de IA no está disponible ahora mismo. El score sí es confiable, es puramente numérico.',
                        style: TextStyle(color: context.kTextSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: score.confianzaPct / 100,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text('${score.confianzaPct}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(etiqueta, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            if (resumen != null && resumen!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(resumen!, style: TextStyle(color: context.kTextPrimary, fontSize: 15, height: 1.5)),
            ],
            if (score.recomendaciones.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Recomendaciones', style: TextStyle(color: context.kTextSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...score.recomendaciones.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.arrow_right_rounded, color: KigoDesign.brand, size: 20),
                        Expanded(child: Text(r, style: TextStyle(color: context.kTextPrimary, fontSize: 14))),
                      ],
                    ),
                  )),
            ],
            if (score.factores.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Factores', style: TextStyle(color: context.kTextSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...score.factores.map(_buildFactor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFactor(FactorScoreModel f) {
    final icono = switch (f.tipo) {
      'positivo' => Icons.add_circle_outline,
      'faltante' => Icons.help_outline,
      _ => Icons.remove_circle_outline,
    };
    final color = switch (f.tipo) {
      'positivo' => const Color(0xFF4CAF50),
      'faltante' => Colors.grey,
      _ => const Color(0xFFE53935),
    };
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.etiqueta, style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  if (f.detalle.isNotEmpty)
                    Text(f.detalle, style: TextStyle(color: context.kTextSecondary, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
