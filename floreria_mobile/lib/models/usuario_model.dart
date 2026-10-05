class UsuarioModel {
  final int? id;
  final String email;
  final String? token;
  final String rol; // 'CLIENTE' o 'ADMIN'

  UsuarioModel({
    this.id,
    required this.email,
    this.token,
    this.rol = 'CLIENTE',
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      email: json['email'] ?? '',
      token: json['access_token'],
      rol: json['rol'] ?? 'CLIENTE',
    );
  }
}

class PedidoModel {
  final int? id;
  final String cliente;
  final String productoNombre;
  final int cantidad;
  final double total;
  final String metodoPago; // 'Efectivo' | 'Tarjeta'
  final String tipoEntrega; // 'Retiro en Tienda' | 'A Domicilio'
  final double? latitud;
  final double? longitud;
  final String? fotoRamoUrl;
  String estado; // 'Visto', 'En Proceso', 'Listo', 'Entregado', 'Recibido'

  PedidoModel({
    this.id,
    required this.cliente,
    required this.productoNombre,
    required this.cantidad,
    required this.total,
    required this.metodoPago,
    required this.tipoEntrega,
    this.latitud,
    this.longitud,
    this.fotoRamoUrl,
    required this.estado,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    return PedidoModel(
      id: json['id'],
      cliente: json['cliente'] ?? '',
      productoNombre: json['productoNombre'] ?? 'Ramo Personalizado',
      cantidad: json['cantidad'] ?? 1,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      metodoPago: json['metodoPago'] ?? 'Efectivo',
      tipoEntrega: json['tipoEntrega'] ?? 'Retiro en Tienda',
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      fotoRamoUrl: json['fotoRamoUrl'],
      estado: json['estado'] ?? 'Visto',
    );
  }
}
