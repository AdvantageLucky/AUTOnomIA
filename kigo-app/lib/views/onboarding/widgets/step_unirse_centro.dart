import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
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
/// del centro → datos del centro (confirmar que es el correcto) → calle →
/// tipo (si la calle tiene más de uno) → número → confirmar. Antes era un
/// campo de texto libre para "casa/destino" — nadie sabía el formato exacto
/// que usó el admin, así que casi nunca coincidía. El último paso ya no
/// pide PIN: lo genera el backend y la persona lo consulta después en "Mi
/// QR".
///
/// El paso `centro` existe para que la persona vea a qué centro se está
/// uniendo (nombre, dirección) ANTES de comprometerse a elegir una casa --
/// tecleó un código a ciegas, y sin esto no había forma de confirmar que
/// era el correcto hasta ya estar eligiendo calle/número.
enum _Paso { codigo, centro, calle, tipo, numero, confirmar }

/// Traduce el tipo de destino a una etiqueta legible -- mismo mapeo que
/// `tipoDisplay()` en backend/internal/domain/destinos/dtos.go. Antes solo
/// distinguía 'edificio' de cualquier otra cosa (relabeleada como "Casa"),
/// así que departamento/oficina/local/bodega/lote se mostraban todos como
/// "Casa" aunque el dato real ya llegaba correcto del backend.
String _etiquetaTipoDestino(BuildContext context, String tipo) {
  switch (tipo) {
    case 'departamento':
      return AppLocalizations.t(context, 'tipo_departamento');
    case 'edificio':
      return AppLocalizations.t(context, 'tipo_edificio');
    case 'oficina':
      return AppLocalizations.t(context, 'tipo_oficina');
    case 'local':
      return AppLocalizations.t(context, 'tipo_local');
    case 'bodega':
      return AppLocalizations.t(context, 'tipo_bodega');
    case 'lote':
      return AppLocalizations.t(context, 'tipo_lote');
    case 'casa':
    default:
      return AppLocalizations.t(context, 'tipo_casa');
  }
}

class _StepUnirseCentroState extends State<StepUnirseCentro> {
  final _codigoCtrl = TextEditingController();
  String? _errorLocal;

  _Paso _paso = _Paso.codigo;
  bool _cargandoDestinos = false;
  List<Map<String, dynamic>> _destinos = [];
  String? _centroNombre;
  String? _centroDescripcion;
  String? _centroDireccion;
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
      setState(() => _errorLocal = AppLocalizations.t(context, 'ingresa_codigo_centro'));
      return;
    }
    setState(() {
      _errorLocal = null;
      _cargandoDestinos = true;
    });
    try {
      final data = await ApiService().get('/personas/me/centros/$codigo/destinos');
      if (!mounted) return;
      final destinos = List<Map<String, dynamic>>.from(data['destinos'] ?? []);
      if (destinos.isEmpty) {
        setState(() {
          _errorLocal = AppLocalizations.t(context, 'centro_sin_casas');
          _cargandoDestinos = false;
        });
        return;
      }
      final centro = Map<String, dynamic>.from(data['centro'] ?? {});
      setState(() {
        _destinos = destinos;
        _centroNombre = centro['nombre'] as String?;
        _centroDescripcion = centro['descripcion'] as String?;
        _centroDireccion = centro['direccion'] as String?;
        _cargandoDestinos = false;
        _paso = _Paso.centro;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorLocal = e.message;
        _cargandoDestinos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorLocal = AppLocalizations.t(context, 'error_verificar_codigo');
        _cargandoDestinos = false;
      });
    }
  }

  /// El botón "Unirme" del paso `centro` NO manda todavía la solicitud al
  /// backend -- eso sigue pasando hasta `_confirmar()`, cuando ya se eligió
  /// la casa. Aquí solo confirma la intención de continuar con ESTE centro.
  void _continuarConEsteCentro() {
    setState(() => _paso = _Paso.calle);
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
        case _Paso.centro:
          _paso = _Paso.codigo;
        case _Paso.calle:
          _paso = _Paso.centro;
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
          Text(_titulo(context), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(_subtitulo(context)),
          const SizedBox(height: 20),
          _buildContenido(context, auth),
          if (_errorLocal ?? auth.error case final mensaje?) ...[
            const SizedBox(height: 8),
            Text(mensaje, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  String _titulo(BuildContext context) {
    switch (_paso) {
      case _Paso.codigo:
        return AppLocalizations.t(context, 'unete_a_tu_centro');
      case _Paso.centro:
        return _centroNombre ?? AppLocalizations.t(context, 'tu_centro');
      case _Paso.calle:
        return AppLocalizations.t(context, 'en_que_calle_vives');
      case _Paso.tipo:
        return AppLocalizations.t(context, 'cual_es_tu_destino');
      case _Paso.numero:
        return AppLocalizations.t(context, 'cual_es_el_numero');
      case _Paso.confirmar:
        return AppLocalizations.t(context, 'confirma_tu_casa');
    }
  }

  String _subtitulo(BuildContext context) {
    switch (_paso) {
      case _Paso.codigo:
        return AppLocalizations.t(context, 'pide_codigo_admin');
      case _Paso.centro:
        return AppLocalizations.t(context, 'es_este_tu_centro');
      case _Paso.calle:
        return AppLocalizations.t(context, 'elige_calle');
      case _Paso.tipo:
        return _calleSeleccionada ?? '';
      case _Paso.numero:
        return '$_calleSeleccionada · ${_etiquetaTipoDestino(context, _tipoSeleccionado ?? 'casa')}';
      case _Paso.confirmar:
        return AppLocalizations.t(context, 'al_unirte_generamos_pin');
    }
  }

  Widget _buildContenido(BuildContext context, AuthViewModel auth) {
    switch (_paso) {
      case _Paso.codigo:
        return Column(
          children: [
            KigoTextField(controller: _codigoCtrl, label: AppLocalizations.t(context, 'codigo_del_centro')),
            const SizedBox(height: 20),
            KigoPrimaryButton(
              label: AppLocalizations.t(context, 'buscar_btn'),
              loading: _cargandoDestinos,
              onPressed: _buscarCentro,
            ),
          ],
        );
      case _Paso.centro:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((_centroDescripcion ?? '').isNotEmpty || (_centroDireccion ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.textDimmed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((_centroDescripcion ?? '').isNotEmpty) ...[
                      Text(_centroDescripcion!),
                      if ((_centroDireccion ?? '').isNotEmpty) const SizedBox(height: 10),
                    ],
                    if ((_centroDireccion ?? '').isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textDimmed),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_centroDireccion!)),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            KigoPrimaryButton(label: AppLocalizations.t(context, 'unirme_btn'), onPressed: _continuarConEsteCentro),
          ],
        );
      case _Paso.calle:
        return _buildLista(_calles, (c) => c, _elegirCalle);
      case _Paso.tipo:
        return _buildLista(
          _tiposDeLaCalle,
          (tipo) => _etiquetaTipoDestino(context, tipo),
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
            KigoPrimaryButton(
              label: AppLocalizations.t(context, 'unirme_btn'),
              loading: auth.isLoading,
              onPressed: _confirmar,
            ),
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
