import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Refuerzo textual persistente (no un tooltip que desaparece) de que el
/// ícono de la mascota es un asistente con el que se puede hablar --
/// tercer canal de descubribilidad junto con la narración automática
/// (visual) y la presentación verbal única (ver
/// AsistentePresentacionServicio).
class EtiquetaAsistente extends StatelessWidget {
  const EtiquetaAsistente({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.t(context, 'asistente_etiqueta'),
      style: TextStyle(color: context.kTextTertiary, fontSize: 11, fontWeight: FontWeight.w600),
    );
  }
}
