import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente.dart';

/// Posiciona [BotonAsistente] siempre en el mismo lugar (arriba a la
/// derecha, mismo offset) sin importar qué header tenga la pantalla debajo
/// — antes cada pantalla lo colocaba a mano con un mecanismo distinto (Row,
/// Align, AppBar.actions) y el resultado no caía exactamente igual en las
/// tres. Debe usarse como hijo directo de un `Stack` que cubra la pantalla.
class BotonAsistenteFlotante extends StatelessWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;

  const BotonAsistenteFlotante({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12 + MediaQuery.paddingOf(context).top,
      right: 12,
      child: BotonAsistente(
        tipoCampo: tipoCampo,
        onRespuestaLibre: onRespuestaLibre,
        onCampoExtraido: onCampoExtraido,
      ),
    );
  }
}
