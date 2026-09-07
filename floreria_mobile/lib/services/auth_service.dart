import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://10.0.2.2:3000/api/v1/usuarios';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  Future<Map<String, dynamic>> registrar(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'rol': 'CLIENTE',
        }),
      );

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'No se pudo crear la cuenta'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de red'};
    }
  }
}
