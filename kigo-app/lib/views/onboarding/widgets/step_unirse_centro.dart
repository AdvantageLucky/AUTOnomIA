import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../widgets/kigo_primary_button.dart';
import '../../../widgets/kigo_text_field.dart';

class StepUnirseCentro extends StatefulWidget {
  final VoidCallback onUnido;
  const StepUnirseCentro({super.key, required this.onUnido});

  @override
  State<StepUnirseCentro> createState() => _StepUnirseCentroState();
}

/// Selección progresiva de destino, igual que el picker del kiosko: código
/// del centro → calle → tipo (si la calle tiene más de uno) → número →
/// confirmar. Antes era un campo de texto libre para "casa/destino" —
/// nadie sabía el formato exacto que usó el admin, así que casi nunca
/// coincidía. El último paso ya no pide PIN: lo genera el backend y la
/// persona lo consulta después en "Mi QR".
enum _Paso { codigo, calle, tipo, numero, confirmar }

class _StepUnirseCentroState extends State<StepUnirseCentro> {
  final _codigoCtrl = TextEditingController();
  String? _errorLocal;

  _Paso _paso = _Paso.codigo;
  bool _cargandoDestinos = false;
  List<Map<String, dynamic>> _destinos = [];
  String? _calleSeleccionada;
  String? _tipoSeleccionado;
  String? _casaSeleccionada;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  List<String> get _calles {
    final set = _destinos.map((d) => (d['calle'] as String?) ?? '').where((c) => c.isNotEmpty).toSet();
    return set.toList()..sort();
  }

  List<Map<String, dynamic>> get _destinosDeLaCalle =>
      _destinos.where((d) => d['calle'] == _calleSeleccionada).toList();

  List<String> get _tiposDeLaCalle =>
      _destinosDeLaCalle.map((d) => (d['tipo'] as String?) ?? '').where((t) => t.isNotEmpty).toSet().toList()..sort();

  List<Map<String, dynamic>> get _numerosVisibles {
    final lista = _destinosDeLaCalle.where((d) => d['tipo'] == _tipoSeleccionado).toList();
    lista.sort((a, b) => ((a['numero'] as String?) ?? '').compareTo((b['numero'] as String?) ?? ''));
    return lista;
  }

  Future<void> _buscarCentro() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      setState(() => _errorLocal = 'Ingresa el código del centro');
      return;
    }
    setState(() {
      _errorLocal = null;
      _cargandoDestinos = true;
    });
    try {
      final data = await ApiService().get('/personas/me/centros/$codigo/destinos');
      final destinos = List<Map<String, dynamic>>.from(data['destinos'] ?? []);
      if (destinos.isEmpty) {
        setState(() {
          _errorLocal = 'Ese centro todavía no tiene casas registradas — avisa a tu administrador';
          _cargandoDestinos = false;
        });
        return;
      }
      setState(() {
        _destinos = destinos;
        _cargandoDestinos = false;
        _paso = _Paso.calle;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorLocal = e.message;
        _cargandoDestinos = false;
      });
    } catch (_) {
      setState(() {
        _errorLocal = 'No se pudo verificar el código, intenta de nuevo';
        _cargandoDestinos = false;
      });
    }
  }

  void _elegirCalle(String calle) {
    final tipos = _destinos.where((d) => d['calle'] == calle).map((d) => d['tipo'] as String?).whereType<String>().toSet();
    setState(() {
      _calleSeleccionada = calle;
      if (tipos.length <= 1) {
        _tipoSeleccionado = tipos.isEmpty ? null : tipos.first;
        _paso = _Paso.numero;
      } else {
        _paso = _Paso.tipo;
      }
    });
  }

  void _elegirTipo(String tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      _paso = _Paso.numero;
    });
  }

  void _elegirNumero(Map<String, dynamic> destino) {
    setState(() {
      _casaSeleccionada = destino['nombre'] as String?;
      _paso = _Paso.confirmar;
    });
  }

  void _regresar() {
    setState(() {
      _errorLocal = null;
      switch (_paso) {
        case _Paso.codigo:
          break;
        case _Paso.calle:
          _paso = _Paso.codigo;
        case _Paso.tipo:
          _paso = _Paso.calle;
          _calleSeleccionada = null;
        case _Paso.numero:
          _paso = _tiposDeLaCalle.length <= 1 ? _Paso.calle : _Paso.tipo;
          _tipoSeleccionado = null;
        case _Paso.confirmar:
          _paso = _Paso.numero;
          _casaSeleccionada = null;
      }
    });
  }

  Future<void> _confirmar() async {
    setState(() => _errorLocal = null);

    final auth = context.read<AuthViewModel>();
    try {
      await auth.unirseCentro(_codigoCtrl.text.trim(), _casaSeleccionada!);
      widget.onUnido();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_paso != _Paso.codigo)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: _regresar,
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          Text(_titulo(), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(_subtitulo()),
          const SizedBox(height: 20),
          _buildContenido(auth),
          if (_errorLocal ?? auth.error case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  String _titulo() {
    switch (_paso) {
      case _Paso.codigo:
        return 'Únete a tu centro';
      case _Paso.calle:
        return '¿En qué calle vives?';
      case _Paso.tipo:
        return '¿Casa o edificio?';
      case _Paso.numero:
        return '¿Cuál es el número?';
      case _Paso.confirmar:
        return 'Confirma tu casa';
    }
  }

  String _subtitulo() {
    switch (_paso) {
      case _Paso.codigo:
        return 'Pide el código a tu administrador si no lo tienes.';
      case _Paso.calle:
        return 'Elige la calle de tu casa o edificio.';
      case _Paso.tipo:
        return _calleSeleccionada ?? '';
      case _Paso.numero:
        return '$_calleSeleccionada · ${_tipoSeleccionado == 'edificio' ? 'Edificio' : 'Casa'}';
      case _Paso.confirmar:
        return 'Al unirte generamos tu PIN de 5 dígitos; lo encuentras en "Mi QR".';
    }
  }

  Widget _buildContenido(AuthViewModel auth) {
    switch (_paso) {
      case _Paso.codigo:
        return Column(
          children: [
            KigoTextField(controller: _codigoCtrl, label: 'Código del centro'),
            const SizedBox(height: 20),
            KigoPrimaryButton(label: 'Buscar', loading: _cargandoDestinos, onPressed: _buscarCentro),
          ],
        );
      case _Paso.calle:
        return _buildLista(_calles, (c) => c, _elegirCalle);
      case _Paso.tipo:
        return _buildLista(
          _tiposDeLaCalle,
          (t) => t == 'edificio' ? 'Edificio' : 'Casa',
          _elegirTipo,
        );
      case _Paso.numero:
        return _buildLista(
          _numerosVisibles,
          (d) => (d['numero'] as String?) ?? '—',
          _elegirNumero,
        );
      case _Paso.confirmar:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.textDimmed.withValues(alpha: 0.3)),
              ),
              child: Text(
                _casaSeleccionada ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            KigoPrimaryButton(label: 'Unirme', loading: auth.isLoading, onPressed: _confirmar),
          ],
        );
    }
  }

  /// Lista genérica de opciones tocables — misma tarjeta para calle, tipo y
  /// número, solo cambia qué texto muestra cada una.
  Widget _buildLista<T>(List<T> items, String Function(T) etiqueta, void Function(T) onTap) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => onTap(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.textDimmed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(etiqueta(item), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
