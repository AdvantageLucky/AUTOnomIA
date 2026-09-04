import 'package:flutter/foundation.dart';
import '../models/visita_pendiente_model.dart';
import '../services/api_service.dart';

/// Visitas pendientes de la casa de la Membresia activa — ver spec
/// 2026-08-17-kigo-app-rediseno-design.md §2.
class PendingVisitsViewModel extends ChangeNotifier {
  List<VisitaPendienteModel> _visitas = [];
  bool _isLoading = false;
  String? _error;
  // Un invitado frecuente (Rol invitado_frecuente) no puede ver solicitudes
  // -- el backend responde 403 con este mismo texto siempre que la acción
  // sea exclusiva de residente (ver persona.handlers.go). Se distingue del
  // resto de los 403/errores para que la pantalla lo muestre como algo
  // esperado (no como una falla de red que un "reintentar" fuera a arreglar).
  bool _soloResidentes = false;

  List<VisitaPendienteModel> get visitas => _visitas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get soloResidentes => _soloResidentes;

  Future<void> cargar(int tenantId) async {
    _isLoading = true;
    _error = null;
    _soloResidentes = false;
    notifyListeners();
    try {
      final data = await ApiService().get('/personas/me/visitas/pendientes?tenant_id=$tenantId');
      final list = (data['visitas'] as List).cast<Map<String, dynamic>>();
      _visitas = list.map(VisitaPendienteModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
      _soloResidentes = e.statusCode == 403 && e.message.contains('solo para residentes');
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
