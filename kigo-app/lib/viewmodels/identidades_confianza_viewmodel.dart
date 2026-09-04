import 'package:flutter/foundation.dart';
import '../models/identidad_resumen_model.dart';
import '../services/api_service.dart';

/// Identidades (residentes, invitados por QR, visitantes con INE) que han
/// visitado la casa del residente autenticado -- para poder "olvidar" el
/// historial acumulado con ellas, igual que el admin puede hacerlo desde el
/// dashboard, pero acotado a "solo lo mío" (ver
/// persona.Handler.ListarIdentidadesMiCasa/ResetHistorialContacto en el backend).
class IdentidadesConfianzaViewModel extends ChangeNotifier {
  List<IdentidadResumenModel> _identidades = [];
  bool _isLoading = false;
  String? _error;
  bool _soloResidentes = false;

  List<IdentidadResumenModel> get identidades => _identidades;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get soloResidentes => _soloResidentes;

  Future<void> cargar(int tenantId) async {
    _isLoading = true;
    _error = null;
    _soloResidentes = false;
    notifyListeners();
    try {
      final data = await ApiService().get('/personas/me/identidades-mi-casa?tenant_id=$tenantId');
      final list = (data['identidades'] as List).cast<Map<String, dynamic>>();
      _identidades = list.map(IdentidadResumenModel.fromJson).toList();
    } on ApiException catch (e) {
      _error = e.message;
      _soloResidentes = e.statusCode == 403 && e.message.contains('solo para residentes');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetear(int tenantId, IdentidadResumenModel identidad) async {
    final url = identidad.personaId != null
        ? '/personas/contactos/${identidad.personaId}/resetear-historial?tenant_id=$tenantId'
        : '/personas/contactos/curp/${Uri.encodeComponent(identidad.curp ?? '')}/resetear-historial?tenant_id=$tenantId';
    try {
      await ApiService().post(url, {}, auth: true);
      _identidades.removeWhere((i) => i.key == identidad.key);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
