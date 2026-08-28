import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Foto de rostro que capturó el kiosko, con sus tres estados: cargando,
/// cargada y sin foto.
///
/// El caso "sin foto" tiene que decirlo con todas sus letras — un hueco vacío
/// se lee como que la imagen no cargó, y son situaciones distintas para quien
/// autoriza. Tocarla la abre a pantalla completa con zoom: en la tarjeta se ve
/// el encuadre, pero reconocer a alguien a veces pide acercarse.
class VisitaFoto extends StatelessWidget {
  const VisitaFoto({
    super.key,
    required this.url,
    this.radio,
    this.compacta = false,
  });

  final String url;

  /// Esquinas redondeadas propias. Se omite cuando quien la monta ya recorta
  /// (una `Card` con `clipBehavior`, por ejemplo).
  final BorderRadius? radio;

  /// Miniatura de lista: oculta el texto del marcador, que no cabe.
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fondo = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;

    Widget contenido;
    if (url.isEmpty) {
      contenido = _Marcador(
        fondo: fondo,
        texto: compacta ? null : 'El kiosko no tomó foto',
      );
    } else {
      contenido = GestureDetector(
        onTap: () => _abrirCompleta(context),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progreso) {
            if (progreso == null) return child;
            return Container(
              color: fondo,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            );
          },
          errorBuilder: (context, _, __) => _Marcador(
            fondo: fondo,
            texto: compacta ? null : 'No se pudo cargar la foto',
          ),
        ),
      );
    }

    if (radio == null) return contenido;
    return ClipRRect(borderRadius: radio!, child: contenido);
  }

  void _abrirCompleta(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  const _Marcador({required this.fondo, this.texto});

  final Color fondo;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fondo,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: texto == null ? 26 : 56,
            color: AppTheme.textGrey,
          ),
          if (texto != null) ...[
            const SizedBox(height: 10),
            Text(texto!, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          ],
        ],
      ),
    );
  }
}
