class Usuario {
  final int id;
  final String email;
  final String rol; // 'CLIENTE' o 'ADMIN'
  final String token;

  Usuario({
    required this.id,
    required this.email,
    required this.rol,
    required this.token,
  });

  factory Usuario.fromJson(Map<String, dynamic> json, String token) {
    return Usuario(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'CLIENTE',
      token: token,
    );
  }
}
