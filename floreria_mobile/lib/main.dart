import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  bool isAdmin = false;
  String? authToken; // Guarda el token JWT tras un login exitoso

  // URLs base del Backend NestJS
  final String apiUrl = 'http://10.0.2.2:3000/api/flores';
  final String pedidosUrl = 'http://10.0.2.2:3000/api/pedidos';
  final String loginUrl = 'http://10.0.2.2:3000/api/auth/login';

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
        if (mounted) {
          setState(() {
            flores = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        _showSnackBar('Error al cargar catálogo (${response.statusCode})');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error de conexión con el servidor');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _loginDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Iniciar Sesión - Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Usuario / Email'),
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
            onPressed: () {
              userCtrl.dispose();
              passCtrl.dispose();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final user = userCtrl.text.trim();
              final pass = passCtrl.text.trim();

              if (user.isEmpty || pass.isEmpty) {
                _showSnackBar('Complete todos los campos');
                return;
              }

              try {
                final res = await http.post(
                  Uri.parse(loginUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'email': user, 'password': pass}),
                );

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  userCtrl.dispose();
                  passCtrl.dispose();

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    final data = json.decode(res.body);
                    setState(() {
                      isAdmin = true;
                      authToken = data['access_token'];
                    });
                    _showSnackBar('Sesión iniciada como Administrador');
                  } else {
                    _showSnackBar('Credenciales incorrectas');
                  }
                }
              } catch (e) {
                _showSnackBar('Error al conectar con la API');
              }
            },
            child: const Text('Ingresar'),
          ),
        ],
      ),
    );
  }

  void _hacerPedido(dynamic flor) {
    final clienteCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
            onPressed: () {
              clienteCtrl.dispose();
              cantidadCtrl.dispose();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final cliente = clienteCtrl.text.trim();
              final cantidad = int.tryParse(cantidadCtrl.text);

              if (cliente.isEmpty || cantidad == null || cantidad <= 0) {
                _showSnackBar('Ingrese datos válidos');
                return;
              }

              try {
                final res = await http.post(
                  Uri.parse(pedidosUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'florId': flor['id'],
                    'cliente': cliente,
                    'cantidad': cantidad,
                  }),
                );

                if (mounted) {
                  Navigator.pop(dialogCtx);
                  clienteCtrl.dispose();
                  cantidadCtrl.dispose();

                  if (res.statusCode == 201 || res.statusCode == 200) {
                    _showSnackBar('¡Pedido registrado exitosamente!');
                    fetchFlores(); // Actualiza el stock en la vista
                  } else {
                    _showSnackBar(
                      'No se pudo procesar el pedido (Stock insuficiente u otro error)',
                    );
                  }
                }
              } catch (e) {
                _showSnackBar('Error al enviar el pedido');
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
        builder: (context) => PedidosScreen(
          pedidosUrl: pedidosUrl,
          isAdmin: isAdmin,
          token: authToken,
        ),
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
            tooltip: 'Ver Pedidos',
            onPressed: _verPedidos,
          ),
          IconButton(
            icon: Icon(isAdmin ? Icons.logout : Icons.admin_panel_settings),
            onPressed: () {
              if (isAdmin) {
                setState(() {
                  isAdmin = false;
                  authToken = null;
                });
                _showSnackBar('Sesión cerrada');
              } else {
                _loginDialog();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchFlores,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : flores.isEmpty
            ? const Center(child: Text('No hay productos disponibles.'))
            : ListView.builder(
                itemCount: flores.length,
                itemBuilder: (context, index) {
                  final flor = flores[index];
                  final imagenUrl = flor['imagenUrl'] ?? '';

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
                            child: imagenUrl.isNotEmpty
                                ? Image.network(
                                    imagenUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(
                                          Icons.local_florist,
                                          size: 50,
                                          color: Colors.pink,
                                        ),
                                  )
                                : const Icon(
                                    Icons.local_florist,
                                    size: 50,
                                    color: Colors.pink,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flor['nombre'] ?? 'Sin Nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  flor['descripcion'] ?? '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${flor['precio']}',
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Stock: ${flor['stock'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (flor['stock'] ?? 0) > 0
                                        ? Colors.green[700]
                                        : Colors.red,
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
                            onPressed: (flor['stock'] ?? 0) > 0
                                ? () => _hacerPedido(flor)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
                    builder: (context) =>
                        AddFlorScreen(apiUrl: apiUrl, token: authToken),
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
  final String? token;

  const PedidosScreen({
    super.key,
    required this.pedidosUrl,
    required this.isAdmin,
    this.token,
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
      final headers = <String, String>{};
      if (widget.token != null) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final res = await http.get(
        Uri.parse(widget.pedidosUrl),
        headers: headers,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            pedidos = json.decode(res.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'Recibido':
      case 'Aprobado':
        return Colors.blue;
      case 'Enviado':
        return Colors.purple;
      case 'Retirado':
      case 'Entregado':
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
          : pedidos.isEmpty
          ? const Center(child: Text('No hay pedidos registrados.'))
          : ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final p = pedidos[index];
                final florNombre = p['flor'] != null
                    ? p['flor']['nombre']
                    : 'Producto';
                final estado = p['estado'] ?? 'Pendiente';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('Cliente: ${p['cliente']}'),
                    subtitle: Text(
                      'Producto: $florNombre\nCantidad: ${p['cantidad']}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(estado),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado,
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
  final String? token;

  const AddFlorScreen({super.key, required this.apiUrl, this.token});

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

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Future<void> _guardarFlor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (widget.token != null) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final response = await http.post(
        Uri.parse(widget.apiUrl),
        headers: headers,
        body: json.encode({
          'nombre': _nombreController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'precio': double.parse(_precioController.text.trim()),
          'stock': int.parse(_stockController.text.trim()),
          'imagenUrl': _imagenUrlController.text.trim().isNotEmpty
              ? _imagenUrlController.text.trim()
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar (${response.statusCode})'),
            ),
          );
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
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingrese un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingrese una descripción'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Precio (\$)'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Ingrese el precio';
                  if (double.tryParse(val.trim()) == null)
                    return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Ingrese el stock';
                  if (int.tryParse(val.trim()) == null)
                    return 'Ingrese un entero válido';
                  return null;
                },
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
