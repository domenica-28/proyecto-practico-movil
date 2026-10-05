import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import 'pedidos_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Simulación de catálogo de flores
  final List<Map<String, dynamic>> flores = [
    {'id': 1, 'nombre': 'Ramo de Rosas Rojas', 'precio': 25.0, 'stock': 10},
    {'id': 2, 'nombre': 'Arreglo de Girasoles', 'precio': 20.0, 'stock': 5},
    {'id': 3, 'nombre': 'Caja de Tulipan Azul', 'precio': 35.0, 'stock': 8},
  ];

  void _abrirModalPedido(Map<String, dynamic> flor) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    int cantidad = 1;
    String metodoPago = 'Efectivo';
    String tipoEntrega = 'Retiro en Tienda';
    File? imagenRamoCustom;
    Position? ubicacionGps;
    bool buscandoGps = false;
    bool cargandoPedido = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalCalculado = flor['precio'] * cantidad;

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
                    'Realizar Pedido: ${flor['nombre']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),

                  // 1. Cantidad y Cálculo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cantidad:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: cantidad > 1
                                ? () => setModalState(() => cantidad--)
                                : null,
                          ),
                          Text(
                            '$cantidad',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setModalState(() => cantidad++),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Foto Personalizada del Ramo
                  const SizedBox(height: 10),
                  const Text('¿Deseas personalizar tu ramo? Adjunta una foto:'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (img != null) {
                            setModalState(
                              () => imagenRamoCustom = File(img.path),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null) {
                            setModalState(
                              () => imagenRamoCustom = File(img.path),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (imagenRamoCustom != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Image.file(
                        imagenRamoCustom!,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),

                  // 3. Método de Pago
                  const SizedBox(height: 10),
                  const Text(
                    'Método de Pago:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: metodoPago,
                    isExpanded: true,
                    items: ['Efectivo', 'Tarjeta'].map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (val) => setModalState(() => metodoPago = val!),
                  ),

                  // 4. Tipo de Entrega y Ubicación GPS
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
                      icon: buscandoGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        ubicacionGps == null
                            ? 'Obtener Ubicación Actual (GPS)'
                            : 'Ubicación Guardada (${ubicacionGps!.latitude.toStringAsFixed(3)}, ${ubicacionGps!.longitude.toStringAsFixed(3)})',
                      ),
                      onPressed: () async {
                        setModalState(() => buscandoGps = true);
                        LocationPermission perm =
                            await Geolocator.requestPermission();
                        if (perm != LocationPermission.denied) {
                          Position pos = await Geolocator.getCurrentPosition();
                          setModalState(() {
                            ubicacionGps = pos;
                            buscandoGps = false;
                          });
                        }
                      },
                    ),
                  ],

                  // 5. Total
                  const Divider(),
                  Text(
                    'TOTAL A PAGAR: \$${totalCalculado.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirmación y Petición HTTP Real
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    onPressed: cargandoPedido
                        ? null
                        : () async {
                            if (tipoEntrega == 'A Domicilio' &&
                                ubicacionGps == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Por favor capture su ubicación GPS para el envío',
                                  ),
                                ),
                              );
                              return;
                            }

                            setModalState(() => cargandoPedido = true);

                            try {
                              // Cambia esta URL por la IP de tu PC si estás probando en celular real
                              // Ej: http://192.168.1.55:3000/api/pedidos
                              final url = Uri.parse(
                                  'http://192.168.100.14:3000/api/pedidos');

                              final response = await http.post(
                                url,
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'florId': flor['id'],
                                  'userId': auth
                                      .userId, // Asegúrate de que tu auth_provider tenga este campo o el ID del usuario
                                  'cantidad': cantidad,
                                  'precioTotal': totalCalculado,
                                  'metodoPago': metodoPago,
                                  'tipoEntrega': tipoEntrega,
                                }),
                              );

                              if (response.statusCode == 201) {
                                Navigator.pop(modalCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '¡Pedido registrado correctamente!'),
                                  ),
                                );
                              } else {
                                final errorData = jsonDecode(response.body);
                                throw Exception(errorData['message'] ??
                                    'Error desconocido');
                              }
                            } catch (e) {
                              setModalState(() => cargandoPedido = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error al registrar pedido: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: cargandoPedido
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirmar Pedido'),
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.esAdmin ? 'Panel Admin - Florería' : 'Catálogo de Flores',
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Mis Pedidos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PedidosScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: flores.length,
        itemBuilder: (context, index) {
          final item = flores[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(
                Icons.local_florist,
                color: Colors.pink,
                size: 40,
              ),
              title: Text(item['nombre']),
              subtitle: Text(
                'Precio: \$${item['precio']} - Stock: ${item['stock']}',
              ),
              trailing: ElevatedButton(
                onPressed: () => _abrirModalPedido(item),
                child: const Text('Pedir'),
              ),
            ),
          );
        },
      ),
    );
  }
}
