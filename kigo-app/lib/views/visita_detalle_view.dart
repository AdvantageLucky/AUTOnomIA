import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/score_ia_model.dart';
import '../theme/app_theme.dart';
import '../widgets/visita_foto.dart';

/// Detalle de una visita: fotos que capturó el kiosko, el score de confianza
/// (ya recortado por el backend a lo que es seguro mostrarle a un residente
/// -- ver FiltrarScoreParaResidente en el backend) y, si el visitante puso
/// teléfono, un acceso directo para llamarlo. Se usa tanto para una
/// solicitud pendiente como para una ya resuelta del historial.
class VisitaDetalleView extends StatelessWidget {
  const VisitaDetalleView({
    super.key,
    required this.titular,
    required this.casaDestino,
    required this.fotoRostroUrl,
    required this.fotoDocumentoUrl,
    required this.fotoPlacaUrl,
    required this.placa,
    required this.tipoVisitante,
    required this.scoreIa,
    required this.createdAt,
    this.telefono = '',
    this.curp = '',
    this.estado,
    this.autorizadoPorNombre,
  });

  final String titular;
  final String casaDestino;
  final String fotoRostroUrl;
  final String fotoDocumentoUrl;
  final String fotoPlacaUrl;
  final String placa;
  final String tipoVisitante;

  /// Solo viene si el visitante ya es una cuenta verificada de Kigo.
  final String telefono;

  /// CURP capturada en esta entrada -- vacía si el flujo no pidió
  /// documento (p. ej. acceso vehicular).
  final String curp;

  /// Null si el backend no pudo calcularlo (p. ej. visita muy vieja, antes
  /// de que existiera el análisis).
  final ScoreIaModel? scoreIa;

  final DateTime createdAt;

  /// Null mientras la solicitud sigue pendiente.
  final String? estado;
  final String? autorizadoPorNombre;

  static const _etiquetaTipo = {
    'VISITANTE': 'Visitante sin invitación',
    'INVITADO': 'Invitado',
    'RESIDENTE': 'Residente',
  };

  @override
  Widget build(BuildContext context) {
    final fotos = <(String, String)>[
      // Antes 'Rostro' se incluía siempre, sin filtrar por .isNotEmpty como
      // las otras dos -- una visita sin captura de rostro (p. ej. acceso
      // solo vehicular) mostraba una miniatura rota en vez de omitirse.
      if (fotoRostroUrl.isNotEmpty) ('Rostro', fotoRostroUrl),
      if (fotoDocumentoUrl.isNotEmpty) ('Identificación', fotoDocumentoUrl),
      if (fotoPlacaUrl.isNotEmpty) ('Placa', fotoPlacaUrl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la visita')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(titular, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${_etiquetaTipo[tipoVisitante] ?? tipoVisitante} · $casaDestino',
            style: const TextStyle(color: AppTheme.textDimmed, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _fmtFechaHora(createdAt),
            style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13),
          ),
          if (placa.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Placa: $placa', style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13)),
          ],
          if (curp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('CURP: $curp', style: const TextStyle(color: AppTheme.textDimmed, fontSize: 13)),
          ],
          if (estado != null) ...[
            const SizedBox(height: 10),
            _ChipEstado(estado: estado!, autorizadoPorNombre: autorizadoPorNombre),
          ],
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: telefono)),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Llamar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://wa.me/${telefono.replaceAll(RegExp(r'[^0-9]'), '')}'),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
          if (fotos.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final (etiqueta, url) = fotos[i];
                return SizedBox(
                  width: 105,
                  child: Column(
                    children: [
                      Expanded(
                        child: VisitaFoto(url: url, radio: BorderRadius.circular(AppTheme.radius)),
                      ),
                      const SizedBox(height: 4),
                      Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppTheme.textDimmed)),
                    ],
                  ),
                );
              },
            ),
          ),
          ],
          if (scoreIa != null) ...[
            const SizedBox(height: 24),
            _ScoreConfianza(score: scoreIa!),
          ],
        ],
      ),
    );
  }

  String _fmtFechaHora(DateTime d) {
    final local = d.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year} · $hora:$min';
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado, this.autorizadoPorNombre});

  final String estado;
  final String? autorizadoPorNombre;

  @override
  Widget build(BuildContext context) {
    final (color, texto) = switch (estado) {
      'APROBADO' => (AppTheme.success, 'Aprobada'),
      'RECHAZADO' => (AppTheme.error, 'Rechazada'),
      'REVISION' => (AppTheme.primaryOrange, 'En revisión'),
      _ => (AppTheme.textDimmed, estado),
    };
    final sufijo = (autorizadoPorNombre?.isNotEmpty ?? false) ? ' por $autorizadoPorNombre' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$texto$sufijo',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScoreConfianza extends StatelessWidget {
  const _ScoreConfianza({required this.score});

  final ScoreIaModel score;

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta) = switch (score.nivelConfianza) {
      'alta' => (AppTheme.success, 'Confianza alta'),
      'media' => (AppTheme.primaryOrange, 'Confianza media'),
      _ => (AppTheme.error, 'Confianza baja'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score.confianzaPct / 100,
                    strokeWidth: 5,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Text('${score.confianzaPct}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(etiqueta, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        if (!score.generadoPorIA) ...[
          const SizedBox(height: 10),
          const Text(
            'Análisis automático (asistente de IA no disponible)',
            style: TextStyle(color: AppTheme.textDimmed, fontSize: 12),
          ),
        ],
        if (score.factores.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...score.factores.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      f.tipo == 'positivo'
                          ? Icons.add_circle_outline
                          : f.tipo == 'faltante'
                              ? Icons.help_outline
                              : Icons.remove_circle_outline,
                      size: 18,
                      color: f.tipo == 'positivo' ? AppTheme.success : AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (f.detalle.isNotEmpty)
                            Text(f.detalle, style: const TextStyle(color: AppTheme.textDimmed, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
