import 'package:flutter/material.dart';

import '../models/usuario_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UsuarioModel? _usuario;
  bool _isLoading = false;

  UsuarioModel? get usuario => _usuario;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuario != null && _usuario!.token != null;

  // Método para Iniciar Sesión
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.login(email, password);

    _isLoading = false;
    if (user != null) {
      _usuario = user;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  // Nuevo método para Registrar Cuenta con Nombre y Apellido
  Future<bool> register(
      String nombre, String apellido, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.register(nombre, apellido, email, password);

    _isLoading = false;
    if (user != null) {
      _usuario = user;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  // Método para Cerrar Sesión
  void logout() {
    _usuario = null;
    notifyListeners();
  }
}
