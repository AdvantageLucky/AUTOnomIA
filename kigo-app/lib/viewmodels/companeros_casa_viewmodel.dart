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
      final list = (data['companeros'] as List).cast<Map<String, dynamic>>();
      _companeros = list.map(CompaneroCasa.fromJson).toList();
      _casaDestino = data['casa_destino'] as String? ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo conectar al servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
