import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<dynamic> pedidos = [];
  bool isLoading = true;
  String errorMessage = '';

  final String baseUrl = 'http://192.168.100.14:3000/api/pedidos';

  final List<String> estadosDisponibles = [
    'Pendiente',
    'Pendiente Pago',
    'Visto',
    'En Proceso',
    'Listo para Retiro',
    'En Camino',
    'Entregado',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      String url = baseUrl;
      if (!auth.esAdmin && auth.usuario?.id != null) {
        url = '$baseUrl?userId=${auth.usuario!.id}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          pedidos = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error al cargar pedidos del servidor';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _actualizarEstado(int pedidoId, String nuevoEstado) async {
    try {
      final urlLimpia = Uri.parse('http://192.168.100.14:3000/api/pedidos');

      final response = await http.patch(
        urlLimpia,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pedidoId': pedidoId,
          'estado': nuevoEstado,
        }),
      );

      if (response.statusCode == 200) {
        _cargarPedidos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a: $nuevoEstado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el estado')),
        );
      }
    } catch (e) {
      print('Error al actualizar: $e');
    }
  }

  void _mostrarSelectorEstado(
      BuildContext context, int pedidoId, String estadoActual) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionar nuevo estado:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...estadosDisponibles.map((estado) => ListTile(
                    title: Text(estado),
                    trailing: estadoActual == estado
                        ? const Icon(Icons.check, color: Colors.pinkAccent)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _actualizarEstado(pedidoId, estado);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.esAdmin
              ? 'Administrar Pedidos (${pedidos.length})'
              : 'Mis Pedidos',
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : pedidos.isEmpty
                  ? const Center(child: Text('No hay pedidos registrados'))
                  : ListView.builder(
                      itemCount: pedidos.length,
                      itemBuilder: (context, index) {
                        final item = pedidos[index];

                        final id = item['id'];
                        final florNombre = item['flor']?['nombre'] ??
                            item['nombreFlor'] ??
                            'Arreglo Floral';

                        final clienteEmail = item['user']?['email'] ??
                            item['correo'] ??
                            'Cliente general';

                        final cantidad = item['cantidad'] ?? 1;
                        final precioTotal =
                            item['precioTotal'] ?? item['total'] ?? 0.0;
                        final metodoPago = item['metodoPago'] ?? 'Efectivo';
                        final tipoEntrega =
                            item['tipoEntrega'] ?? 'A Domicilio';
                        final estado = item['estado'] ?? 'Pendiente';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pedido #$id - $florNombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Cliente: $clienteEmail',
                                    style: const TextStyle(color: Colors.grey)),
                                Text(
                                    'Cantidad: $cantidad | Total: \$$precioTotal'),
                                Text(
                                    'Pago: $metodoPago | Entrega: $tipoEntrega'),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Chip(
                                      label: Text(estado),
                                      backgroundColor: estado == 'Entregado'
                                          ? Colors.green[100]
                                          : estado == 'En Camino' ||
                                                  estado == 'En Proceso'
                                              ? Colors.blue[100]
                                              : Colors.orange[100],
                                    ),
                                    if (auth.esAdmin)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pinkAccent,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          _mostrarSelectorEstado(
                                              context, id, estado);
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Cambiar Estado'),
                                      ),
                                    if (!auth.esAdmin && estado != 'Entregado')
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        onPressed: () {
                                          _actualizarEstado(id, 'Entregado');
                                        },
                                        child: const Text(
                                          'Marcar Recibido',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
