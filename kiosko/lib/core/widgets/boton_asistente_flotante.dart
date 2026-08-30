import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente.dart';

/// Posiciona [BotonAsistente] siempre a la derecha, alineado con la fila de
/// header propia de cada pantalla — antes cada pantalla lo colocaba a mano
/// con un mecanismo distinto (Row, Align, AppBar.actions) y el resultado no
/// caía exactamente igual en las tres. Debe usarse como hijo directo de un
/// `Stack` que cubra la pantalla.
///
/// [topDelBorde] es el offset vertical (respecto al borde superior de
/// pantalla, sin contar el safe area, que se suma aparte) del header de esa
/// pantalla en particular -- no hay un único valor correcto para las tres,
/// cada una define su propio padding/estructura de header. Pásalo igual al
/// padding/inset real que usa esa pantalla para su fila de arriba.
class BotonAsistenteFlotante extends StatelessWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;
  final double topDelBorde;

  const BotonAsistenteFlotante({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
    required this.topDelBorde,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topDelBorde + MediaQuery.paddingOf(context).top,
      right: 12,
      child: BotonAsistente(
        tipoCampo: tipoCampo,
        onRespuestaLibre: onRespuestaLibre,
        onCampoExtraido: onCampoExtraido,
      ),
    );
  }
}
