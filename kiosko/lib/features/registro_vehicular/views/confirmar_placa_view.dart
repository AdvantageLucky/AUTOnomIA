/* CONFIRMACIÓN Y CORRECCIÓN MANUAL DE LA PLACA LEÍDA */

import 'package:flutter/material.dart';
import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:kigo_kiosco/features/registro_vehicular/services/placa_detector_servicio.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

/// Respaldo manual cuando la lectura automática de placa (hardware dedicado,
/// ver PlacaLectorServicio) no resolvió a tiempo — deja escribirla a mano.
///
/// Devuelve la placa confirmada, o null si el visitante cancela.
Future<String?> pedirConfirmacionPlaca(
  BuildContext context, {
  String? placaLeida,
}) {
  return Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => ConfirmarPlacaView(placaLeida: placaLeida)),
  );
}

/// Captura la placa con un teclado propio en pantalla.
///
/// No usa `TextField`: la app corre en `SystemUiMode.immersiveSticky` y re-aplica
/// el modo inmersivo en cada resume, así que abrir el teclado del sistema deja a
/// la app y al IME peleándose por las barras de sistema hasta colgar el hilo
/// principal (ANR). Además, en modo kiosko con lock task (ADR-0014) el teclado
/// del sistema es una superficie que no queremos exponer. El resto de la app ya
/// resuelve así sus entradas: PIN de residente, PIN de operador y código de
/// activación tienen todos su propio teclado.
class ConfirmarPlacaView extends StatefulWidget {
  final String? placaLeida;

  const ConfirmarPlacaView({super.key, this.placaLeida});

  @override
  State<ConfirmarPlacaView> createState() => _ConfirmarPlacaViewState();
}

class _ConfirmarPlacaViewState extends State<ConfirmarPlacaView> {
  static const int _maxLength = 8;

  late String _placa = PlacaDetectorServicio.normalizar(widget.placaLeida ?? '');
  String? _error;
  String? _presionadoId;

  bool get _fueLeida => widget.placaLeida != null;

  void _agregar(String caracter) {
    if (_placa.length >= _maxLength) return;
    setState(() {
      _placa += caracter;
      _error = null;
    });
  }

  void _borrar() {
    if (_placa.isEmpty) return;
    setState(() {
      _placa = _placa.substring(0, _placa.length - 1);
      _error = null;
    });
  }

  void _confirmar() {
    if (!PlacaDetectorServicio.pareceValida(_placa)) {
      setState(() => _error = AppLocalizations.t(context, 'placa_error_incompleta'));
      return;
    }
    Navigator.pop(context, _placa);
  }

  void _onCampoExtraido(CampoExtraido campo) {
    final valor = campo.valor;
    if (valor == null) return;
    setState(() {
      _placa = PlacaDetectorServicio.normalizar(valor);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // El teclado QWERTY completo + encabezado + acciones no siempre
                // cabe en pantallas chicas — se envuelve en scroll en vez de
                // desbordar, forzando al menos la altura disponible para que el
                // Spacer siga empujando el teclado hacia abajo cuando sí cabe.
                return SingleChildScrollView(
                  // El teclado + botón de confirmar (ancho completo) quedaban
                  // detrás del micrófono/vigilante sin esta reserva extra.
                  padding: EdgeInsets.fromLTRB(28, 20, 28, 20 + KigoDesign.clearanceBotonesFlotantes),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildDisplay(),
                          const SizedBox(height: 8),
                          _buildError(),
                          const Spacer(),
                          _buildKeypad(),
                          const SizedBox(height: 20),
                          _buildAcciones(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Coincide con el padding vertical/horizontal del
          // SingleChildScrollView de esta pantalla (20/28) para alinear con
          // el header real.
          topDelBorde: 20,
          rightDelBorde: 28,
          tipoCampo: 'placa',
          onRespuestaLibre: (_) {}, // esta pantalla no usa Q&A libre
          onCampoExtraido: _onCampoExtraido,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          _fueLeida ? Icons.directions_car_rounded : Icons.edit_note_rounded,
          color: KigoDesign.brand,
          size: 44,
        ),
        const SizedBox(height: 12),
        Text(
          _fueLeida
              ? AppLocalizations.t(context, 'confirma_tu_placa')
              : AppLocalizations.t(context, 'escribe_tu_placa'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _fueLeida
              ? AppLocalizations.t(context, 'corrige_caracter_no_coincide')
              : AppLocalizations.t(context, 'no_detectamos_placa_escribela'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.kTextSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: context.kSurface2,
        borderRadius: BorderRadius.circular(KigoDesign.radiusLg),
        border: Border.all(
          color: _error != null
              ? KigoDesign.error
              : KigoDesign.brand.withValues(alpha: 0.35),
          width: 1.8,
        ),
      ),
      child: Text(
        _placa.isEmpty ? 'ABC123D' : _placa,
        textAlign: TextAlign.center,
        style: KigoDesign.mono(TextStyle(
          color: _placa.isEmpty ? context.kTextTertiary : context.kTextPrimary,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 8,
        )),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: 24,
      child: _error == null
          ? null
          : Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KigoDesign.error, fontSize: 15),
            ),
    );
  }

  Widget _buildKeypad() {
    // Distribución QWERTY con fila numérica: es la que el visitante reconoce sin
    // pensarlo, y una placa mezcla letras y dígitos en cualquier orden.
    const filas = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];

    return Column(
      children: [
        ...filas.take(3).map(_buildFila),
        Row(
          children: [
            ...filas[3].map((c) => Expanded(child: _buildTeclaWrap(c))),
            Expanded(flex: 2, child: _buildTeclaWrap('⌫', esBorrar: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildFila(List<String> caracteres) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: caracteres.map((c) => Expanded(child: _buildTeclaWrap(c))).toList(),
      ),
    );
  }

  Widget _buildTeclaWrap(String caracter, {bool esBorrar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _buildTecla(caracter, esBorrar: esBorrar),
    );
  }

  Widget _buildTecla(String caracter, {bool esBorrar = false}) {
    final bool presionado = _presionadoId == caracter;

    return GestureDetector(
      onTapDown: (_) => setState(() => _presionadoId = caracter),
      onTapUp: (_) {
        setState(() => _presionadoId = null);
        if (esBorrar) {
          _borrar();
        } else {
          _agregar(caracter);
        }
      },
      onTapCancel: () => setState(() => _presionadoId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        height: 62,
        decoration: BoxDecoration(
          color: presionado
              ? (esBorrar ? context.kTeclaPresionada : KigoDesign.brandHover)
              : context.kSurface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: presionado
                ? KigoDesign.brandHover
                : KigoDesign.brand.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Center(
          child: esBorrar
              ? Icon(
                  Icons.backspace_outlined,
                  color: presionado ? KigoDesign.brand : context.kTextSecondary,
                  size: 24,
                )
              : Text(
                  caracter,
                  style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAcciones() {
    return Row(
      children: [
        Expanded(
          child: Presionable(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: context.kSurface2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.kBorder, width: 1.2),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.t(context, 'cancelar_button'),
                  style: TextStyle(
                    color: context.kTextSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Presionable(
            onTap: _confirmar,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: KigoDesign.brand,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.t(context, 'continue_button_text'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
