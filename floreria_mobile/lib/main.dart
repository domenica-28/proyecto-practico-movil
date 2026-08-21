import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florería Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const FloresListScreen(),
    );
  }
}

class FloresListScreen extends StatefulWidget {
  const FloresListScreen({super.key});

  @override
  State<FloresListScreen> createState() => _FloresListScreenState();
}

class _FloresListScreenState extends State<FloresListScreen> {
  List<dynamic> flores = [];
  bool isLoading = true;
  bool isAdmin = false; // Control de sesión de Administrador

  final String apiUrl = 'http://10.0.2.2:3000/api/flores';
  final String pedidosUrl = 'http://10.0.2.2:3000/api/pedidos';
  final String loginUrl = 'http://10.0.2.2:3000/api/login';

  @override
  void initState() {
    super.initState();
    fetchFlores();
  }

  Future<void> fetchFlores() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          flores = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loginDialog() {
    TextEditingController userCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Sesión - Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final res = await http.post(
                Uri.parse(loginUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'usuario': userCtrl.text,
                  'password': passCtrl.text,
                }),
              );

              if (mounted) {
                Navigator.pop(context);
                if (res.statusCode == 200) {
                  setState(() => isAdmin = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesión iniciada como Administradora'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Credenciales incorrectas')),
                  );
                }
              }
            },
            child: const Text('Ingresar'),
          ),
        ],
      ),
    );
  }

  void _hacerPedido(dynamic flor) {
    TextEditingController clienteCtrl = TextEditingController();
    TextEditingController cantidadCtrl = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedido: ${flor['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clienteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Cliente',
              ),
            ),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (clienteCtrl.text.isEmpty) return;
              final res = await http.post(
                Uri.parse(pedidosUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'florId': flor['id'],
                  'cliente': clienteCtrl.text,
                  'cantidad': int.parse(cantidadCtrl.text),
                }),
              );

              if (mounted) {
                Navigator.pop(context);
                if (res.statusCode == 201) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Pedido realizado! Estado actual: Pendiente',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar Compra'),
          ),
        ],
      ),
    );
  }

  void _verPedidos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PedidosScreen(pedidosUrl: pedidosUrl, isAdmin: isAdmin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Catálogo (Admin)' : 'Catálogo de Florería'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ver Mis Pedidos',
            onPressed: _verPedidos,
          ),
          IconButton(
            icon: Icon(isAdmin ? Icons.logout : Icons.admin_panel_settings),
            onPressed: () {
              if (isAdmin) {
                setState(() => isAdmin = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión de administración cerrada'),
                  ),
                );
              } else {
                _loginDialog();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: flores.length,
              itemBuilder: (context, index) {
                final flor = flores[index];
                final imagenUrl =
                    flor['imagenUrl'] ?? 'https://via.placeholder.com/150';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imagenUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.local_florist,
                                  size: 50,
                                  color: Colors.pink,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                flor['nombre'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                flor['descripcion'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '\$${flor['precio']}',
                                style: const TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.pinkAccent,
                          ),
                          onPressed: () => _hacerPedido(flor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddFlorScreen(apiUrl: apiUrl),
                  ),
                );
                if (result == true) fetchFlores();
              },
            )
          : null,
    );
  }
}

class PedidosScreen extends StatefulWidget {
  final String pedidosUrl;
  final bool isAdmin;
  const PedidosScreen({
    super.key,
    required this.pedidosUrl,
    required this.isAdmin,
  });

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<dynamic> pedidos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPedidos();
  }

  Future<void> fetchPedidos() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(widget.pedidosUrl));
      if (res.statusCode == 200) {
        setState(() {
          pedidos = json.decode(res.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Recibido':
        return Colors.blue;
      case 'Enviado':
        return Colors.orange;
      case 'Retirado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Pedidos'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final p = pedidos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      'Cliente: ${p['cliente']} - Flor: ${p['flor']['nombre']}',
                    ),
                    subtitle: Text(
                      'Cantidad: ${p['cantidad']} | Estado: ${p['estado']}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(p['estado']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p['estado'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AddFlorScreen extends StatefulWidget {
  final String apiUrl;
  const AddFlorScreen({super.key, required this.apiUrl});

  @override
  State<AddFlorScreen> createState() => _AddFlorScreenState();
}

class _AddFlorScreenState extends State<AddFlorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  bool isSubmitting = false;

  Future<void> _guardarFlor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(widget.apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text,
          'descripcion': _descripcionController.text,
          'precio': double.parse(_precioController.text),
          'stock': int.parse(_stockController.text),
          'imagenUrl': _imagenUrlController.text.isNotEmpty
              ? _imagenUrlController.text
              : null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Producto registrado con éxito!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Producto'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Flor',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (val) => val == null || val.isEmpty
                    ? 'Ingrese una descripción'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio (\$)'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ingrese el precio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Ingrese el stock' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen (Opcional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isSubmitting ? null : _guardarFlor,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Producto',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
