import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class InvitationViewModel extends ChangeNotifier {
  List<InvitationModel> _invitations = [];
  bool _isLoading = false;
  String? _error;

  List<InvitationModel> get invitations => _invitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // token cache: id → token (los tokens no vienen en el listado, solo en la creación)
  Map<int, String> _tokenCache = {};

  InvitationViewModel() {
    _loadTokenCache();
    fetchInvitations();
  }

  Future<void> _loadTokenCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefsTokenCache);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _tokenCache = map.map((k, v) => MapEntry(int.parse(k), v as String));
    }
  }

  Future<void> _saveTokenCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _tokenCache.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(AppConstants.prefsTokenCache, jsonEncode(map));
  }

  Future<void> fetchInvitations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().get('/residentes/me/invitaciones/');
      final list = (data as List).map((e) => InvitationModel.fromJson(e)).toList();
      // inyectar tokens del cache
      _invitations = list.map((inv) {
        final cached = _tokenCache[inv.id];
        return cached != null ? inv.copyWith(token: cached) : inv;
      }).toList();
      // limpiar tokens de invitaciones que ya no existen
      final activeIds = _invitations.map((i) => i.id).toSet();
      _tokenCache.removeWhere((k, _) => !activeIds.contains(k));
      await _saveTokenCache();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo conectar al servidor';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<InvitationModel?> createInvitation({
    required String titular,
    required String tipo,
    required int destinoId,
    int? maxUsos,
    DateTime? expiresAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'titular': titular,
        'tipo': tipo,
        'destino_id': destinoId,
      };
      if (maxUsos != null) body['max_usos'] = maxUsos;
      if (expiresAt != null) body['expires_at'] = expiresAt.toUtc().toIso8601String();

      final data = await ApiService().post('/residentes/me/invitaciones/', body, auth: true);
      final inv = InvitationModel.fromJson(data);

      // cachear el token (solo viene en la creación)
      if (inv.token != null) {
        _tokenCache[inv.id] = inv.token!;
        await _saveTokenCache();
      }

      _invitations.insert(0, inv);
      notifyListeners();
      return inv;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'No se pudo conectar al servidor';
      notifyListeners();
      return null;
    }
  }

  Future<bool> revokeInvitation(int id) async {
    try {
      await ApiService().delete('/residentes/me/invitaciones/$id');
      _tokenCache.remove(id);
      await _saveTokenCache();
      _invitations.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'No se pudo conectar al servidor';
      notifyListeners();
      return false;
    }
  }
}
