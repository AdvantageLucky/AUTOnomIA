import 'package:kigo_kiosco/core/models/campo_extraido.dart';
import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:kigo_kiosco/core/widgets/boton_asistente_flotante.dart';
import 'package:kigo_kiosco/core/widgets/presionable.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';
import 'package:kigo_kiosco/l10n/app_localizations.dart';

class CasaDestinoView extends StatefulWidget {
  /// El indicador de pasos se parametriza porque el flujo vehicular tiene más
  /// capturas antes de llegar aquí. La casa destino siempre es el penúltimo.
  final int totalSteps;

  /// Posicion de este paso en el pipeline. Ya no se deduce restando 2 al
  /// total: DESTINO es un paso ordenable desde el dashboard, asi que puede
  /// caer en cualquier lugar y no solo antes del resumen.
  final int currentStep;

  const CasaDestinoView({
    super.key,
    this.totalSteps = 4,
    this.currentStep = 2,
  });

  @override
  State<CasaDestinoView> createState() => _CasaDestinoViewState();
}

/// Selección progresiva: calle → tipo (si la calle tiene más de uno) →
/// número → motivo. Una lista plana de todas las casas no escala a un
/// fraccionamiento con decenas o cientos de unidades. MOTIVO va al final,
/// una vez que ya se sabe a dónde va, porque es la captura del núcleo
/// obligatorio del reto FEPRO ("Nombre, motivo, anfitrión/destino") que
/// antes no existía en ningún paso del kiosko.
enum _SubPaso { calle, tipo, numero, motivo }

/// Motivos frecuentes como chips de un toque -- pedir el motivo por texto
/// con teclado va contra el listón de "menos de 3 minutos, sin
/// entrenamiento" del PRD. "Otro" cae al mismo campo libre que ya existe
/// para destino, por si ninguno aplica.
const _motivosFrecuentes = [
  'Visita',
  'Entrega o paquetería',
  'Servicio o mantenimiento',
  'Proveedor',
];

class _CasaDestinoViewState extends State<CasaDestinoView> {
  final KioskoServicio _kioskoServicio = KioskoServicio();
  List<Map<String, dynamic>>? _destinos;
  bool _isLoading = true;
  String? _error;

  _SubPaso _subPaso = _SubPaso.calle;
  String? _calleSeleccionada;
  String? _tipoSeleccionado;
  String? _destinoSugeridoPorVoz;
  String? _destinoElegido;

  void _onCampoExtraido(CampoExtraido campo) {
    final valor = campo.valor;
    if (valor == null || _destinos == null) return;
    final existe = _destinos!.any((d) => d['nombre'] == valor);
    if (!existe) return;
    setState(() => _destinoSugeridoPorVoz = valor);
  }

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  Future<void> _cargarDestinos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final destinos = await _kioskoServicio.obtenerDestinos();
      if (!mounted) return;
      setState(() {
        _destinos = destinos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.t(context, 'no_se_pudo_cargar_casas');
        _isLoading = false;
      });
    }
  }

  List<String> get _calles {
    final set = <String>{};
    for (final d in _destinos ?? []) {
      final calle = (d['calle'] as String?)?.trim() ?? '';
      if (calle.isNotEmpty) set.add(calle);
    }
    final lista = set.toList()..sort();
    return lista;
  }

  List<Map<String, dynamic>> get _destinosDeLaCalle {
    return (_destinos ?? []).where((d) => d['calle'] == _calleSeleccionada).toList();
  }

  List<String> get _tiposDeLaCalle {
    final set = <String>{};
    for (final d in _destinosDeLaCalle) {
      final tipo = d['tipo'] as String?;
      if (tipo != null) set.add(tipo);
    }
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _numerosVisibles {
    return _destinosDeLaCalle.where((d) => d['tipo'] == _tipoSeleccionado).toList()
      ..sort((a, b) => (a['numero'] as String? ?? '').compareTo(b['numero'] as String? ?? ''));
  }

  void _elegirCalle(String calle) {
    final tipos = (_destinos ?? [])
        .where((d) => d['calle'] == calle)
        .map((d) => d['tipo'] as String?)
        .whereType<String>()
        .toSet();
    setState(() {
      _calleSeleccionada = calle;
      if (tipos.length <= 1) {
        _tipoSeleccionado = tipos.isEmpty ? null : tipos.first;
        _subPaso = _SubPaso.numero;
      } else {
        _subPaso = _SubPaso.tipo;
      }
    });
  }

  void _elegirTipo(String tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      _subPaso = _SubPaso.numero;
    });
  }

  void _regresar() {
    switch (_subPaso) {
      case _SubPaso.calle:
        Navigator.pop(context);
      case _SubPaso.tipo:
        setState(() {
          _subPaso = _SubPaso.calle;
          _calleSeleccionada = null;
        });
      case _SubPaso.numero:
        final tipos = _tiposDeLaCalle;
        setState(() {
          if (tipos.length <= 1) {
            _subPaso = _SubPaso.calle;
            _calleSeleccionada = null;
          } else {
            _subPaso = _SubPaso.tipo;
          }
          _tipoSeleccionado = null;
        });
      case _SubPaso.motivo:
        setState(() {
          _subPaso = _SubPaso.numero;
          _destinoElegido = null;
        });
    }
  }

  /// Todos los caminos para elegir destino (tarjeta de número, sugerencia
  /// de voz, escritura manual) convergen aquí en vez de cerrar la pantalla
  /// directo -- así el motivo se captura sin importar cómo se llegó al
  /// destino.
  void _irAMotivo(String destino) {
    setState(() {
      _destinoElegido = destino;
      _destinoSugeridoPorVoz = null;
      _subPaso = _SubPaso.motivo;
    });
  }

  void _confirmarMotivo(String motivo) {
    Navigator.pop(context, {'destino': _destinoElegido ?? '', 'motivo': motivo});
  }

  @override
  Widget build(BuildContext context) {
    if (_destinoSugeridoPorVoz != null) {
      return Scaffold(
        backgroundColor: context.kBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Tu destino es "${_destinoSugeridoPorVoz!}"?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() => _destinoSugeridoPorVoz = null),
                        child: const Text('No, elegir manualmente'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _irAMotivo(_destinoSugeridoPorVoz!),
                        style: ElevatedButton.styleFrom(backgroundColor: KigoDesign.brand),
                        child: const Text('Sí, confirmar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.kBg,
          appBar: AppBar(
            backgroundColor: context.kBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.kTextPrimary),
              onPressed: _regresar,
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(left: 42, right: 42, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepIndicator(
                    currentStep: widget.currentStep,
                    totalSteps: widget.totalSteps,
                  ),
                  const SizedBox(height: 42),
                  Text(_titulo(), style: TextStyle(color: context.kTextPrimary, fontSize: 34, fontWeight: FontWeight.w800)),
                  if (_subtitulo() != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _subtitulo()!,
                      style: TextStyle(color: context.kTextSecondary, fontSize: 17),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildContenido(),
                  if (!_isLoading && _error == null && _subPaso != _SubPaso.motivo) ...[
                    const SizedBox(height: 24),
                    _buildBotonNoEncuentroDestino(),
                  ],
                ],
              ),
            ),
          ),
        ),
        BotonAsistenteFlotante(
          // Esta pantalla sigue usando un AppBar real (kToolbarHeight=56)
          // para el botón de atrás, y el botón del asistente ya no cabe
          // centrado en esa franja: mide KigoDesign.ladoAsistente (76). Se
          // ancla arriba y cuelga ~20px sobre el scroll -- queda fuera del
          // padding horizontal del contenido (42 vs 16), así que no tapa el
          // StepIndicator. rightDelBorde 16 replica el inset estándar que
          // Flutter usa para las actions de un AppBar. Falta confirmarlo en
          // dispositivo real.
          topDelBorde: 0,
          rightDelBorde: 16,
          tipoCampo: 'destino',
          onRespuestaLibre: (_) {}, // esta pantalla no usa Q&A libre
          onCampoExtraido: _onCampoExtraido,
        ),
      ],
    );
  }

  String _titulo() {
    switch (_subPaso) {
      case _SubPaso.calle:
        return AppLocalizations.t(context, 'en_que_calle_esta_destino');
      case _SubPaso.tipo:
        return AppLocalizations.t(context, 'casa_o_edificio');
      case _SubPaso.numero:
        return AppLocalizations.t(context, 'cual_es_el_numero');
      case _SubPaso.motivo:
        return '¿Cuál es el motivo de tu visita?';
    }
  }

  String? _subtitulo() {
    if (_subPaso == _SubPaso.calle || _subPaso == _SubPaso.motivo) return null;
    return _calleSeleccionada;
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: KigoDesign.brand)),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.wifi_off_rounded, color: context.kTextSecondary, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.kTextSecondary, fontSize: 18),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _cargarDestinos,
              style: ElevatedButton.styleFrom(
                backgroundColor: KigoDesign.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                AppLocalizations.t(context, 'reintentar'),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBotonNoEncuentroDestino(),
        ],
      );
    }

    if ((_destinos ?? []).isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            AppLocalizations.t(context, 'sin_casas_registradas'),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.kTextSecondary, fontSize: 18),
          ),
        ),
      );
    }

    switch (_subPaso) {
      case _SubPaso.calle:
        return Column(
          children: _calles
              .map((c) => _buildCard(
                    icono: Icons.signpost_outlined,
                    titulo: c,
                    onTap: () => _elegirCalle(c),
                  ))
              .toList(),
        );
      case _SubPaso.tipo:
        return Column(
          children: _tiposDeLaCalle
              .map((t) => _buildCard(
                    icono: _iconoDeTipo(t),
                    titulo: _etiquetaDeTipo(t),
                    onTap: () => _elegirTipo(t),
                  ))
              .toList(),
        );
      case _SubPaso.numero:
        return Column(
          children: _numerosVisibles
              .map((d) => _buildCard(
                    icono: _iconoDeTipo(_tipoSeleccionado),
                    titulo: d['numero'] as String? ?? '—',
                    onTap: () => _irAMotivo(d['nombre'] as String? ?? ''),
                  ))
              .toList(),
        );
      case _SubPaso.motivo:
        return Column(
          children: [
            ..._motivosFrecuentes.map((m) => _buildCard(
                  icono: Icons.info_outline_rounded,
                  titulo: m,
                  onTap: () => _confirmarMotivo(m),
                )),
            _buildCard(
              icono: Icons.more_horiz_rounded,
              titulo: AppLocalizations.t(context, 'otro_destino_label'),
              onTap: _escribirMotivoManual,
            ),
          ],
        );
    }
  }

  /// El dashboard permite 7 tipos de destino (casa, departamento, oficina,
  /// local, bodega, lote y otro). Antes esto era un binario: cualquier cosa
  /// que no fuera 'edificio' se pintaba como "Casa", así que un departamento
  /// o una bodega salían rotulados como casa.
  ///
  /// El default no inventa un tipo: capitaliza lo que haya llegado. Si el
  /// dashboard aprende un tipo nuevo antes que el APK del kiosko, se ve el
  /// nombre crudo — feo, pero cierto.
  String _etiquetaDeTipo(String? tipo) {
    switch (tipo) {
      case 'casa':
        return AppLocalizations.t(context, 'casa_label');
      case 'departamento':
        return AppLocalizations.t(context, 'departamento_label');
      case 'edificio':
        return AppLocalizations.t(context, 'edificio_label');
      case 'oficina':
        return AppLocalizations.t(context, 'oficina_label');
      case 'local':
        return AppLocalizations.t(context, 'local_label');
      case 'bodega':
        return AppLocalizations.t(context, 'bodega_label');
      case 'lote':
        return AppLocalizations.t(context, 'lote_label');
      case null:
      case '':
        return AppLocalizations.t(context, 'otro_destino_label');
      default:
        return tipo[0].toUpperCase() + tipo.substring(1);
    }
  }

  IconData _iconoDeTipo(String? tipo) {
    switch (tipo) {
      case 'edificio':
      case 'departamento':
        return Icons.apartment_outlined;
      case 'oficina':
        return Icons.business_center_outlined;
      case 'local':
        return Icons.storefront_outlined;
      case 'bodega':
        return Icons.warehouse_outlined;
      case 'lote':
        return Icons.crop_square_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  /// Respaldo cuando el destino del visitante no aparece en la lista jerárquica
  /// (calle/tipo/número): permite escribirlo a mano, igual que aceptaba el
  /// campo libre antes de este selector progresivo.
  Widget _buildBotonNoEncuentroDestino() {
    return Center(
      child: TextButton(
        onPressed: _escribirDestinoManual,
        child: Text(
          AppLocalizations.t(context, 'no_encuentro_mi_destino'),
          style: TextStyle(
            color: context.kTextSecondary,
            fontSize: 15,
            decoration: TextDecoration.underline,
            decorationColor: context.kTextSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _escribirDestinoManual() async {
    final controller = TextEditingController();
    final destino = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.kSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.t(context, 'escribe_tu_destino'),
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
    if (destino != null && destino.isNotEmpty && mounted) {
      _irAMotivo(destino);
    }
  }

  Future<void> _escribirMotivoManual() async {
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.kSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Cuál es el motivo de tu visita?',
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
    if (mounted) _confirmarMotivo(motivo ?? '');
  }

  Widget _buildCard({required IconData icono, required String titulo, required VoidCallback onTap}) {
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
