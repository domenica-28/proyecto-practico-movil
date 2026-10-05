import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario_model.dart';

class AuthService {
  // ⚠️ RECUERDA: 10.0.2.2 es solo para emulador. Si usas cel físico pon tu IP local (ej: 192.168.x.x)
  final String baseUrl = 'http://10.0.2.2:3000/api/auth';

  // Método de Login
  Future<UsuarioModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UsuarioModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error en login: $e');
      return null;
    }
  }

  // Método de Registro (Nuevo)
  Future<UsuarioModel?> register(
      String nombre, String apellido, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UsuarioModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error en register: $e');
      return null;
    }
  }
}
