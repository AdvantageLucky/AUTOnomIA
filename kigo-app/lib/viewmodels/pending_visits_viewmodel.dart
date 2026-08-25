import 'package:flutter/foundation.dart';
import '../models/visita_pendiente_model.dart';
import '../services/api_service.dart';

/// Visitas pendientes de la casa de la Membresia activa — ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §2.
class PendingVisitsViewModel extends ChangeNotifier {
  List<VisitaPendienteModel> _visitas = [];
  bool _isLoading = false;
  String? _error;

  List<VisitaPendienteModel> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargar(int tenantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().get('/personas/me/visitas/pendientes?tenant_id=$tenantId');
      final list = (data['visitas'] as List).cast<Map<String, dynamic>>();
      _visitas = list.map(VisitaPendienteModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> responder(int tenantId, int visitaId, String estado) async {
    try {
      await ApiService().patch(
        '/personas/me/visitas/$visitaId/estado?tenant_id=$tenantId',
        {'estado': estado},
      );
      _visitas.removeWhere((v) => v.id == visitaId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
