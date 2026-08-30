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
///
/// [rightDelBorde] es el equivalente horizontal: el padding derecho real de
/// esa pantalla. Antes estaba fijo en 12 para las tres, lo que dejaba el
/// ícono 16-22px más cerca del borde físico de lo que le correspondía en
/// pantallas con más padding horizontal.
class BotonAsistenteFlotante extends StatelessWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;
  final double topDelBorde;
  final double rightDelBorde;

  const BotonAsistenteFlotante({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
    required this.topDelBorde,
    this.rightDelBorde = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topDelBorde + MediaQuery.paddingOf(context).top,
      right: rightDelBorde,
      child: BotonAsistente(
        tipoCampo: tipoCampo,
        onRespuestaLibre: onRespuestaLibre,
        onCampoExtraido: onCampoExtraido,
      ),
    );
  }
}
