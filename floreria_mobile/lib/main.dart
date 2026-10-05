import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  String? authToken;
  String? usuarioActual;

  final String apiUrl = 'http://192.168.100.14:3000/api/flores';
  final String pedidosUrl = 'http://192.168.100.14:3000/api/pedidos';
  final String loginUrl = 'http://192.168.100.14:3000/api/login';
  final String registerUrl = 'http://192.168.100.14:3000/api/usuarios';

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
          final decodedData = json.decode(response.body);
          setState(() {
            if (decodedData is List) {
              flores = decodedData;
            } else if (decodedData is Map && decodedData.containsKey('data')) {
              flores = decodedData['data'];
            } else if (decodedData is Map &&
                decodedData.containsKey('flores')) {
              flores = decodedData['flores'];
            } else {
              flores = [];
            }
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

  Future<Position?> _obtenerUbicacionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Por favor active el GPS de su dispositivo');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Permiso de ubicación denegado');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Los permisos de ubicación están bloqueados');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _authDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool esRegistro = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(esRegistro ? 'Crear Cuenta' : 'Iniciar Sesión'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correo / Usuario',
                    ),
                  ),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      setDialogState(() => esRegistro = !esRegistro);
                    },
                    child: Text(
                      esRegistro
                          ? '¿Ya tienes cuenta? Inicia Sesión'
                          : '¿No tienes cuenta? Regístrate',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
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

                  final targetUrl = esRegistro ? registerUrl : loginUrl;

                  try {
                    final res = await http.post(
                      Uri.parse(targetUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'email': user, 'password': pass}),
                    );

                    if (!mounted) return;

                    if (res.statusCode == 200 || res.statusCode == 201) {
                      final data = json.decode(res.body);

                      if (Navigator.canPop(dialogCtx)) {
                        Navigator.of(dialogCtx).pop();
                      }

                      setState(() {
                        usuarioActual = user;
                        authToken = data['access_token'];
                        isAdmin = user.contains('admin');
                      });

                      _showSnackBar(
                        esRegistro
                            ? '¡Cuenta creada con éxito!'
                            : 'Sesión iniciada correctamente',
                      );
                    } else {
                      _showSnackBar(
                          'Error en las credenciales (${res.statusCode})');
                    }
                  } catch (e) {
                    _showSnackBar('Error de conexión con el servidor');
                  }
                },
                child: Text(esRegistro ? 'Registrar' : 'Ingresar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _hacerPedido(dynamic flor) {
    if (usuarioActual == null) {
      _showSnackBar('Debe iniciar sesión para realizar un pedido');
      _authDialog();
      return;
    }

    int cantidad = 1;
    double precioUnitario = double.tryParse(flor['precio'].toString()) ?? 0.0;
    String metodoPago = 'Efectivo';
    String tipoEntrega = 'Retiro en Tienda';

    File? imagenCustomRamo;
    final ImagePicker picker = ImagePicker();

    double? latitud;
    double? longitud;
    bool obteniendoGps = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalPagar = precioUnitario * cantidad;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido: ${flor['nombre']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cantidad:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: cantidad > 1
                                ? () => setModalState(() => cantidad--)
                                : null,
                          ),
                          Text(
                            '$cantidad',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setModalState(() => cantidad++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Modelo/Diseño de Ramo deseado (Opcional):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Tomar Foto'),
                        onPressed: () async {
                          final XFile? photo = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (photo != null) {
                            setModalState(
                              () => imagenCustomRamo = File(photo.path),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Galería'),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setModalState(
                              () => imagenCustomRamo = File(image.path),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (imagenCustomRamo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imagenCustomRamo!,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Método de Pago:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: metodoPago,
                    isExpanded: true,
                    items: ['Efectivo', 'Tarjeta'].map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) => setModalState(() => metodoPago = val!),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tipo de Entrega:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Retiro en Tienda'),
                    value: 'Retiro en Tienda',
                    groupValue: tipoEntrega,
                    onChanged: (val) => setModalState(() => tipoEntrega = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('A Domicilio'),
                    value: 'A Domicilio',
                    groupValue: tipoEntrega,
                    onChanged: (val) => setModalState(() => tipoEntrega = val!),
                  ),
                  if (tipoEntrega == 'A Domicilio') ...[
                    OutlinedButton.icon(
                      icon: obteniendoGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        latitud == null
                            ? 'Capturar mi Ubicación GPS'
                            : 'Ubicación OK (${latitud!.toStringAsFixed(3)}, ${longitud!.toStringAsFixed(3)})',
                      ),
                      onPressed: obteniendoGps
                          ? null
                          : () async {
                              setModalState(() => obteniendoGps = true);
                              Position? pos = await _obtenerUbicacionActual();
                              setModalState(() {
                                obteniendoGps = false;
                                if (pos != null) {
                                  latitud = pos.latitude;
                                  longitud = pos.longitude;
                                }
                              });
                            },
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL A PAGAR:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${totalPagar.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: () async {
                      if (tipoEntrega == 'A Domicilio' && latitud == null) {
                        _showSnackBar(
                          'Por favor active y registre la ubicación GPS para entrega a domicilio',
                        );
                        return;
                      }

                      try {
                        final res = await http.post(
                          Uri.parse(pedidosUrl),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'florId': flor['id'],
                            'cliente': usuarioActual,
                            'cantidad': cantidad,
                            'total': totalPagar,
                            'metodoPago': metodoPago,
                            'tipoEntrega': tipoEntrega,
                            'latitud': latitud,
                            'longitud': longitud,
                          }),
                        );

                        if (mounted) {
                          Navigator.pop(modalCtx);
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            _showSnackBar('¡Pedido registrado exitosamente!');
                            fetchFlores();
                          } else {
                            _showSnackBar('Error al registrar pedido');
                          }
                        }
                      } catch (e) {
                        _showSnackBar('Error de conexión al enviar el pedido');
                      }
                    },
                    child: const Text('Confirmar Pedido'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _verPedidos() {
    if (usuarioActual == null) {
      _showSnackBar('Inicie sesión para revisar sus pedidos');
      _authDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PedidosScreen(
          pedidosUrl: pedidosUrl,
          isAdmin: isAdmin,
          token: authToken,
          usuarioActual: usuarioActual!,
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
            tooltip: 'Mis Pedidos',
            onPressed: _verPedidos,
          ),
          IconButton(
            icon: Icon(usuarioActual != null ? Icons.logout : Icons.person),
            onPressed: () {
              if (usuarioActual != null) {
                setState(() {
                  usuarioActual = null;
                  isAdmin = false;
                  authToken = null;
                });
                _showSnackBar('Sesión cerrada');
              } else {
                _authDialog();
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
                                      style:
                                          const TextStyle(color: Colors.grey),
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
  final String usuarioActual;

  const PedidosScreen({
    super.key,
    required this.pedidosUrl,
    required this.isAdmin,
    this.token,
    required this.usuarioActual,
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

      Uri uri = Uri.parse(widget.pedidosUrl);
      if (!widget.isAdmin) {
        uri = uri.replace(queryParameters: {'userId': widget.usuarioActual});
      }

      final res = await http.get(
        uri,
        headers: headers,
      );

      if (res.statusCode == 200) {
        if (mounted) {
          final decoded = json.decode(res.body);
          List<dynamic> listaPedidos =
              decoded is List ? decoded : (decoded['data'] ?? []);

          setState(() {
            pedidos = widget.isAdmin
                ? listaPedidos
                : listaPedidos
                    .where((p) =>
                        p['cliente'] == widget.usuarioActual ||
                        p['user']?['email'] == widget.usuarioActual)
                    .toList();
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

  Future<void> _actualizarEstado(int pedidoId, String nuevoEstado) async {
    try {
      final res = await http.patch(
        Uri.parse(widget.pedidosUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': pedidoId,
          'estado': nuevoEstado,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        fetchPedidos();
      }
    } catch (e) {
      // Manejo de error silencioso
    }
  }

  Color _getEstadoColor(String? estado) {
    switch (estado) {
      case 'Visto':
        return Colors.orange;
      case 'En Proceso':
        return Colors.blue;
      case 'Listo para Retiro':
      case 'En Camino':
        return Colors.purple;
      case 'Entregado':
      case 'Recibido':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Administrar Pedidos' : 'Mis Pedidos'),
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
                    final florNombre =
                        p['flor'] != null ? p['flor']['nombre'] : 'Producto';
                    final estado = p['estado'] ?? 'Visto';
                    final lat = p['latitud'];
                    final lon = p['longitud'];
                    final total = p['total'] ?? p['precioTotal'] ?? 0.0;
                    final pago = p['metodoPago'] ?? 'Efectivo';
                    final entrega = p['tipoEntrega'] ?? 'Retiro en Tienda';
                    final clienteNombre =
                        p['cliente'] ?? p['user']?['email'] ?? 'Usuario';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente: $clienteNombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Producto: $florNombre x${p['cantidad']}'),
                            Text('Total: \$${total.toString()} | Pago: $pago'),
                            Text('Entrega: $entrega'),
                            if (lat != null && lon != null)
                              Text(
                                'GPS: $lat, $lon',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
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
                                if (widget.isAdmin)
                                  DropdownButton<String>(
                                    value: [
                                      'Visto',
                                      'En Proceso',
                                      'Listo para Retiro',
                                      'En Camino',
                                      'Entregado',
                                    ].contains(estado)
                                        ? estado
                                        : 'Visto',
                                    items: [
                                      'Visto',
                                      'En Proceso',
                                      'Listo para Retiro',
                                      'En Camino',
                                      'Entregado',
                                    ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        _actualizarEstado(p['id'], val);
                                      }
                                    },
                                  ),
                                if (!widget.isAdmin && estado != 'Recibido')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () =>
                                        _actualizarEstado(p['id'], 'Recibido'),
                                    child: const Text(
                                      'Marcar como Recibido',
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

  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _seleccionarImagen(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _imagenSeleccionada = File(image.path);
        _imagenUrlController.clear();
      });
    }
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
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingrese el precio';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Ingrese el stock'
                    : int.tryParse(val.trim()) == null
                        ? 'Stock inválido'
                        : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Imagen del Producto:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_imagenSeleccionada != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imagenSeleccionada!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                    onPressed: () => _seleccionarImagen(ImageSource.camera),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                    onPressed: () => _seleccionarImagen(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'O ingrese una URL de Imagen',
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
