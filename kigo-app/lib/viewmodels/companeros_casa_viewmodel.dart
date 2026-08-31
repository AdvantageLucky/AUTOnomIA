import 'package:flutter/foundation.dart';
import '../models/companero_casa_model.dart';
import '../services/api_service.dart';

/// Compañeros de casa (misma casa_destino, mismo tenant) de la Membresia
/// activa seleccionada — ver spec 2026-08-29-companeros-casa-design.md.
class CompanerosCasaViewModel extends ChangeNotifier {
  List<CompaneroCasa> _companeros = [];
  String _casaDestino = '';
  bool _isLoading = false;
  String? _error;

  List<CompaneroCasa> get companeros => _companeros;
  String get casaDestino => _casaDestino;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargar(int tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService()
          .get('/personas/me/companeros-casa?tenant_id=$tenantId');
      final rawList = data['companeros'];
      if (rawList is List) {
        _companeros = rawList
            .whereType<Map<String, dynamic>>()
            .map(CompaneroCasa.fromJson)
            .toList();
      } else {
        _companeros = [];
      }
      _casaDestino = data['casa_destino'] as String? ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar compañeros de casa: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
