import 'package:flutter/material.dart';

import '../models/usuario_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  final AuthService _authService = AuthService();

  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null;
  bool get isAdmin => _usuario?.rol == 'ADMIN';

  Future<String?> login(String email, String password) async {
    final result = await _authService.login(email, password);
    if (result['success']) {
      final data = result['data'];
      _usuario = Usuario.fromJson(data['usuario'], data['accessToken']);
      notifyListeners(); // Notifica a toda la app que la sesión cambió
      return null; // Sin errores
    } else {
      return result['message'];
    }
  }

  void logout() {
    _usuario = null;
    notifyListeners(); // Limpia la sesión en toda la app
  }
}
