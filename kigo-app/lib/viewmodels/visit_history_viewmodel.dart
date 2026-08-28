import 'package:flutter/foundation.dart';
import '../models/visita_historial_model.dart';
import '../services/api_service.dart';

/// Historial de visitas de la casa de la Membresia activa — todas, en
/// cualquier estado, de la más reciente a la más vieja.
class VisitHistoryViewModel extends ChangeNotifier {
  List<VisitaHistorialModel> _visitas = [];
  bool _isLoading = false;
  String? _error;

  List<VisitaHistorialModel> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargar(int tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService()
          .get('/personas/me/visitas/historial?tenant_id=$tenantId');
      final list = (data['visitas'] as List).cast<Map<String, dynamic>>();
      _visitas = list.map(VisitaHistorialModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
