import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/services/asistente_controller.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente.dart';
import 'package:kigo_kiosco/core/widgets/etiqueta_asistente.dart';

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
///
/// [mostrarEtiqueta] pone "Asistente IA" a la IZQUIERDA del botón, no
/// debajo. Antes cada pantalla la colocaba a mano con su propio
/// `Positioned(top: X + N)`, y ese N tenía que ir creciendo con el botón: al
/// pasar el botón a 76px la etiqueta bajó hasta meterse en el contenido (en
/// el registro táctil caía justo sobre el StepIndicator). Puesta al lado, el
/// asistente ocupa nada más la banda del botón y no invade lo de abajo, sin
/// importar cuánto mida.
class BotonAsistenteFlotante extends StatelessWidget {
  final String? tipoCampo;
  final void Function(String respuesta) onRespuestaLibre;
  final void Function(CampoExtraido) onCampoExtraido;
  final double topDelBorde;
  final double rightDelBorde;
  final AsistenteController? controlador;
  final bool mostrarEtiqueta;

  const BotonAsistenteFlotante({
    super.key,
    this.tipoCampo,
    required this.onRespuestaLibre,
    required this.onCampoExtraido,
    required this.topDelBorde,
    this.rightDelBorde = 12,
    this.controlador,
    this.mostrarEtiqueta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topDelBorde + MediaQuery.paddingOf(context).top,
      right: rightDelBorde,
      // mainAxisSize.min para que la fila crezca hacia la izquierda desde el
      // borde derecho en vez de ocupar todo el ancho del Stack.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarEtiqueta) ...[
            const EtiquetaAsistente(),
            const SizedBox(width: 8),
          ],
          BotonAsistente(
            tipoCampo: tipoCampo,
            onRespuestaLibre: onRespuestaLibre,
            onCampoExtraido: onCampoExtraido,
            controlador: controlador,
          ),
        ],
      ),
    );
  }
}
