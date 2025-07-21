import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../orders_tab.dart';
import 'pedido_detalle.dart';
import 'history.dart';
import 'account.dart';

class RepartidorApp extends StatefulWidget {
  final Map<String, dynamic> repartidorData;
  const RepartidorApp({Key? key, required this.repartidorData}) : super(key: key);

  @override
  State<RepartidorApp> createState() => _RepartidorAppState();
}

class _RepartidorAppState extends State<RepartidorApp> {
  int _currentIndex = 0;
  bool _jornadaActiva = false;
  String? _selectedOrderId;
  Map<String, dynamic>? _selectedOrderData;
  final _pedidosRef = FirebaseFirestore.instance.collection('PEDIDOS');

  final MapController _mapController = MapController();
  LatLng _center = LatLng(-0.9337, -79.2044);
  LatLng? _markerPos;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, 15);
    });
  }

  // Función para obtener la ubicación del repartidor
  Future<void> _locateMe() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu GPS')),
      );
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final me = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _center = me;
      _markerPos = me;
      _mapController.move(me, 17);
    });

    // Llamar a la función para obtener la ruta
    if (_selectedOrderData != null) {
      LatLng? destination = _extractCustomerPoint(_selectedOrderData);
      if (destination != null) {
        _fetchRoadRoute(_center, destination);
      }
    }
  }

  // Función que llama a la API para obtener la ruta entre dos puntos
  Future<void> _fetchRoadRoute(LatLng start, LatLng end) async {
    final coords = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson',
    );
    final res = await http.get(url);

    // Verificar el estado de la respuesta
    if (res.statusCode != 200) {
      throw Exception('OSRM error ${res.statusCode}');
    }

    final data = json.decode(res.body);
    print('Ruta recibida: $data'); // Esto te permite ver la respuesta completa de la API

    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final raw = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;

      final route = raw
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      setState(() {
        _routePoints = route; // Aquí estamos guardando la ruta
        print('Ruta trazada: $_routePoints'); // Verificación de los puntos de la ruta
      });
    } else {
      print('No se recibió una ruta válida.');
    }
  }

  // Función para extraer las coordenadas de los locales
  List<LatLng> _extractLocalPoints(Map<String, dynamic>? orderData) {
    final items = (orderData?['items'] as List<dynamic>?) ?? [];
    return items.cast<Map<String, dynamic>>().map((it) {
      final gp = it['localCoords'];
      if (gp is GeoPoint) {
        return LatLng(gp.latitude, gp.longitude);
      }
      if (gp is List && gp.length == 2 && gp[0] is num && gp[1] is num) {
        return LatLng((gp[0] as num).toDouble(),
            (gp[1] as num).toDouble());
      }
      return null;
    }).whereType<LatLng>().toList();
  }

  // Función para extraer las coordenadas del cliente
  LatLng? _extractCustomerPoint(Map<String, dynamic>? orderData) {
    final gp = orderData?['customerCoords'];
    if (gp is GeoPoint) {
      return LatLng(gp.latitude, gp.longitude);
    }
    if (gp is List && gp.length == 2 && gp[0] is num && gp[1] is num) {
      return LatLng((gp[0] as num).toDouble(),
          (gp[1] as num).toDouble());
    }
    return null;
  }

  // Función para aceptar el pedido
  void _aceptarPedido(int index) async {
    final pedido = PedidosScreen.pedidosActuales[index];

    pedido['status'] = 'En camino';

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final repartidorDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      if (repartidorDoc.exists) {
        final repartidorName = repartidorDoc.data()?['displayName'] ?? 'Repartidor';

        pedido['repartidor'] = repartidorName;

        await FirebaseFirestore.instance
            .collection('PEDIDOS')
            .doc(pedido['id'])
            .update({
              'status': 'En camino',
              'repartidor': repartidorName,
            });

        setState(() {
          PedidosScreen.pedidosActuales[index] = pedido;
        });
      } else {
        print('El repartidor no existe en la base de datos');
      }
    }
  }

  // Función para construir la vista principal
  Widget _buildHomeTab() {
    final locals = _extractLocalPoints(_selectedOrderData);
    final customerPt = _extractCustomerPoint(_selectedOrderData);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _center, zoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                tileProvider: NetworkTileProvider(headers: {
                  'User-Agent': 'easyexpress/1.0',
                  'Referer': 'https://your.domain.com/',
                }),
              ),
              // Asegúrate de que la capa PolylineLayer está activada
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints, // Puntos de la ruta calculada
                      strokeWidth: 4,  // Establece el grosor de la línea de la ruta
                      color: Colors.blue, // Establece el color de la línea de la ruta
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_markerPos != null)
                    Marker(
                      point: _markerPos!,
                      width: 40, height: 40,
                      builder: (_) => const Icon(Icons.person_pin_circle, size: 40, color: Colors.blue),
                    ),
                  for (final locPt in locals)
                    Marker(
                      point: locPt,
                      width: 30, height: 30,
                      builder: (_) => const Icon(Icons.store, size: 30, color: Colors.green),
                    ),
                  if (customerPt != null)
                    Marker(
                      point: customerPt,
                      width: 35, height: 35,
                      builder: (_) => const Icon(Icons.home, size: 35, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.purple,
            onPressed: _locateMe,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: ElevatedButton.icon(
            icon: Icon(_jornadaActiva ? Icons.stop : Icons.play_arrow),
            label: Text(_jornadaActiva ? 'Terminar jornada' : 'Iniciar jornada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _jornadaActiva ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              setState(() {
                _jornadaActiva = !_jornadaActiva;
              });

              // Aquí se llama a _locateMe() para obtener la ubicación actual
              await _locateMe();

              // Llamar a la función de obtener ruta desde la ubicación actual
              if (_selectedOrderData != null) {
                LatLng? destination = _extractCustomerPoint(_selectedOrderData);
                if (destination != null) {
                  // Primero obtener ruta desde la ubicación actual
                  _fetchRoadRoute(_center, destination);
                }
              }
            },
          ),
        ),
        if (_jornadaActiva)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidosRef.where('status', isEqualTo: 'En preparación').snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No hay pedidos pendientes'),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final pid = doc.id;
                    final email = data['customerEmail'] as String? ?? 'Cliente';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('Pedido de $email'),
                        subtitle: Text('Estado: ${data['status']}'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await _pedidosRef.doc(pid).update({'status': 'En curso'});
                            setState(() {
                              _selectedOrderId = pid;
                              _selectedOrderData = {'id': pid, ...data};
                            });
                          },
                          child: Text('Aceptar'),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPedidosTab() {
    if (_selectedOrderData != null) {
      return PedidoDetalleScreen(pedidoId: _selectedOrderId!, pedidoData: _selectedOrderData!);
    }
    return const Center(child: Text('Selecciona un pedido en Inicio'));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.repartidorData['nombre'] as String? ?? '';
    return Scaffold(
      appBar: _currentIndex == 0 // Solo en la sección de Inicio
          ? AppBar(
              title: Text('Bienvenido, $name'),
              backgroundColor: const Color(0xFF6F35A5),
              centerTitle: true,
                      automaticallyImplyLeading: false, 
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildPedidosTab(),
          const HistorialPedidosScreen(), // Historial de pedidos
          CuentaScreen(                     // Sección de Cuenta
            userName: widget.repartidorData['nombre'] ?? '',
            userEmail: widget.repartidorData['email'] ?? '',
            userPhone: widget.repartidorData['phone'] ?? '',
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.purple),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, color: Colors.blue),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.orange),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.green),
            label: 'Cuenta',
          ),
        ],
         selectedItemColor: Colors.black,  // Esto hace que el texto del icono seleccionado sea negro
         unselectedItemColor: Colors.black, // Esto hace que el texto de los iconos no seleccionados sea negro
      ),
    );
  }
}
