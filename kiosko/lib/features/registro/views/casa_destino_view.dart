import 'package:kigo_kiosco/core/theme/kigo_design.dart';
import 'package:flutter/material.dart';
import 'package:kigo_kiosco/features/registro/services/kiosko_servicio.dart';
import 'package:kigo_kiosco/features/registro/views/widgets/step_indicator.dart';

class CasaDestinoView extends StatefulWidget {
  /// El indicador de pasos se parametriza porque el flujo vehicular tiene más
  /// capturas antes de llegar aquí. La casa destino siempre es el penúltimo.
  final int totalSteps;

  const CasaDestinoView({super.key, this.totalSteps = 4});

  @override
  State<CasaDestinoView> createState() => _CasaDestinoViewState();
}

/// Selección progresiva: calle → tipo (si la calle tiene más de uno) →
/// número. Una lista plana de todas las casas no escala a un fraccionamiento
/// con decenas o cientos de unidades.
enum _SubPaso { calle, tipo, numero }

class _CasaDestinoViewState extends State<CasaDestinoView> {
  final KioskoServicio _kioskoServicio = KioskoServicio();
  List<Map<String, dynamic>>? _destinos;
  bool _isLoading = true;
  String? _error;

  _SubPaso _subPaso = _SubPaso.calle;
  String? _calleSeleccionada;
  String? _tipoSeleccionado;

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
        _error = 'No se pudo cargar la lista de casas. Verifica la conexión.';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KigoDesign.bgDark,
      appBar: AppBar(
        backgroundColor: KigoDesign.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                currentStep: widget.totalSteps - 2,
                totalSteps: widget.totalSteps,
              ),
              const SizedBox(height: 42),
              Text(_titulo(), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              if (_subtitulo() != null) ...[
                const SizedBox(height: 8),
                Text(
                  _subtitulo()!,
                  style: const TextStyle(color: Color(0xFF999494), fontSize: 17),
                ),
              ],
              const SizedBox(height: 32),
              _buildContenido(),
            ],
          ),
        ),
      ),
    );
  }

  String _titulo() {
    switch (_subPaso) {
      case _SubPaso.calle:
        return '¿En qué calle está tu destino?';
      case _SubPaso.tipo:
        return '¿Casa o edificio?';
      case _SubPaso.numero:
        return '¿Cuál es el número?';
    }
  }

  String? _subtitulo() {
    if (_subPaso == _SubPaso.calle) return null;
    return _calleSeleccionada;
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF542F))),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.wifi_off_rounded, color: Color(0xFF8F8989), size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC5BFBF), fontSize: 18),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _cargarDestinos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF542F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    if ((_destinos ?? []).isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'Todavía no hay casas registradas en este kiosko.\nAvisa a la administración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF999494), fontSize: 18),
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
                    icono: t == 'edificio' ? Icons.apartment_outlined : Icons.home_outlined,
                    titulo: t == 'edificio' ? 'Edificio' : 'Casa',
                    onTap: () => _elegirTipo(t),
                  ))
              .toList(),
        );
      case _SubPaso.numero:
        return Column(
          children: _numerosVisibles
              .map((d) => _buildCard(
                    icono: Icons.home_outlined,
                    titulo: d['numero'] as String? ?? '—',
                    onTap: () => Navigator.pop(context, d['nombre'] as String?),
                  ))
              .toList(),
        );
    }
  }

  Widget _buildCard({required IconData icono, required String titulo, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1B1B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF302A2A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3A2420),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: const Color(0xFFFF542F), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8F8989), size: 28),
          ],
        ),
      ),
    );
  }
}
