import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/invitation_model.dart';

class InvitationViewModel extends ChangeNotifier {
  List<InvitationModel> _invitations = [];
  final _uuid = const Uuid();
  static const String _storageKey = 'kigo_invitations';

  List<InvitationModel> get invitations => _invitations;

  InvitationViewModel() {
    _loadInvitationsFromStorage();
  }

  // Cargar invitaciones de la memoria local
  Future<void> _loadInvitationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _invitations = jsonList
            .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar invitaciones: $e');
    }
  }

  // Guardar la lista actual en la memoria local
  Future<void> _saveInvitationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(
        _invitations.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error al guardar invitaciones: $e');
    }
  }

  // Crear una nueva invitación
  InvitationModel createInvitation({
    required String name,
    required String company,
    required String reason,
    required DateTime date,
    required String time,
    required int duration,
  }) {
    final newInvitation = InvitationModel(
      id: _uuid.v4(), // Genera un ID único global
      name: name,
      company: company,
      reason: reason,
      date: date,
      time: time,
      duration: duration,
    );

    _invitations.add(newInvitation);
    notifyListeners();
    _saveInvitationsToStorage(); // Persistir cambio
    
    return newInvitation;
  }

  // Eliminar una invitación
  void deleteInvitation(String id) {
    _invitations.removeWhere((invitation) => invitation.id == id);
    notifyListeners();
    _saveInvitationsToStorage(); // Persistir cambio
  }
}