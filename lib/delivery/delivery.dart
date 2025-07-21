import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart'; // Necesario para PolylineLayerOptions, MarkerLayerOptions...
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../orders_tab.dart';

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

  // Control del mapa
  final MapController _mapController = MapController();
  LatLng _center = LatLng(-0.9337, -79.2044);
  LatLng? _markerPos;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    // Centrar al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, 15);
    });
  }

  /// Obtiene la posición actual del repartidor
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
  }

  /// Llama al servicio OSRM para trazar la ruta carretera
  Future<List<LatLng>> _fetchRoadRoute(LatLng start, LatLng end) async {
    final coords =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('OSRM error ${res.statusCode}');
    }
    final data = json.decode(res.body);
    final raw = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
    return raw
        .map((c) =>
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  /// Ruta con paradas intermedias
  Future<List<LatLng>> _fetchMultiStopRoute(List<LatLng> points) async {
    final coords = points.map((p) => '${p.longitude},${p.latitude}').join(';');
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&overview=full'
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('OSRM error ${res.statusCode}');
    }
    final data = json.decode(res.body);
    final raw = data['routes'][0]['geometry']['coordinates'] as List;
    return raw
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  /// Extrae las coordenadas de todos los locales de orderData['items']
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

  /// Extrae la ubicación del cliente desde el campo 'customerCoords'
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

void _aceptarPedido(int index) async {
  final pedido = PedidosScreen.pedidosActuales[index];

  // Cambiar el estado del pedido a "En camino"
  pedido['status'] = 'En camino';

  // Obtener el nombre del repartidor desde la colección 'usuarios'
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId != null) {
    // Obtener el nombre del repartidor desde Firestore
    final repartidorDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();

    if (repartidorDoc.exists) {
      final repartidorName = repartidorDoc.data()?['displayName'] ?? 'Repartidor';
      
      // Asignar el nombre del repartidor al pedido
      pedido['repartidor'] = repartidorName;

      // Actualizar el pedido en Firestore
      await FirebaseFirestore.instance
          .collection('PEDIDOS')
          .doc(pedido['id'])
          .update({
            'status': 'En camino',
            'repartidor': repartidorName,
          });

      // Actualizar la lista de pedidos actuales
      setState(() {
        PedidosScreen.pedidosActuales[index] = pedido;
      });
    } else {
      print('El repartidor no existe en la base de datos');
    }
  }
}



  Widget _buildHomeTab() {
    final locals = _extractLocalPoints(_selectedOrderData);
    final customerPt = _extractCustomerPoint(_selectedOrderData);

    return Stack(
      children: [
        // ─── MAPA PRINCIPAL ─────────────────────────────────────────
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _center, zoom: 15),
            children: [
              // 1) Tile layer base con headers para evitar 403
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a','b','c'],
                tileProvider: NetworkTileProvider(headers: {
                  'User-Agent': 'easyexpress/1.0',
                  'Referer': 'https://your.domain.com/',
                }),
              ),

              // 2) Ruta carretera (si ya calculaste)
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 4),
                  ],
                ),

              // 3) Marcadores
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

        // ─── BOTÓN “MI UBICACIÓN” ────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.purple,
            onPressed: _locateMe,
            child: const Icon(Icons.my_location),
          ),
        ),

        // ─── BOTÓN INICIAR / TERMINAR JORNADA ────────────────────────
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: ElevatedButton.icon(
            icon: Icon(_jornadaActiva ? Icons.stop : Icons.play_arrow),
            label: Text(
                _jornadaActiva ? 'Terminar jornada' : 'Iniciar jornada'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _jornadaActiva ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () =>
                setState(() => _jornadaActiva = !_jornadaActiva),
          ),
        ),

        // ─── LISTA DE PEDIDOS PENDIENTES ─────────────────────────────
        if (_jornadaActiva)
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: StreamBuilder<QuerySnapshot>(
              stream: _pedidosRef
                  .where('status', isEqualTo: 'En preparación')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
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
                    final data =
                        doc.data()! as Map<String, dynamic>;
                    final pid = doc.id;
                    final inProg = pid == _selectedOrderId;
                    final email = data['customerEmail']
                            as String? ??
                        'Cliente';
                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('Pedido de $email'),
                        subtitle: Text(
                            'Estado: ${inProg ? 'En curso' : data['status']}'),
                        trailing: ElevatedButton(
                          onPressed: inProg
                              ? null
                              : () async {
                                  // 1) marco pedido en curso
                                  await _pedidosRef
                                      .doc(pid)
                                      .update({'status': 'En curso'});
                                  // 2) guardo datos y trazo ruta
                                  setState(() {
                                    _selectedOrderId = pid;
                                    _selectedOrderData = {
                                      'id': pid,
                                      ...data
                                    };
                                  });
                                  // 2) preparo origin, locales y cliente
                                  final origin   = _markerPos ?? _center;
                                  final locals   = _extractLocalPoints(_selectedOrderData);
                                  final customer = _extractCustomerPoint(_selectedOrderData);

                                  // 3) valido que tenga coords de cliente
                                  if (customer == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coordenadas de cliente faltantes')),
                                  );
                                  return;
                                  }
                                  // 4) trazo ruta multi‑stop: repartidor → locales… → cliente
                                  final ruta = await _fetchMultiStopRoute(
                                    [origin, ...locals, customer],
                                  );
                                  setState(() => _routePoints = ruta);
                                 // 5) cambio a pestaña detalles
                                  setState(() => _currentIndex = 1);
                                  
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inProg
                                ? Colors.grey
                                : Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20)),
                          ),
                          child: Text(
                              inProg ? 'En curso' : 'Aceptar'),
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
      return PedidoDetalleScreen(
        pedidoId: _selectedOrderId!,
        pedidoData: _selectedOrderData!,
      );
    }
    return const Center(
        child: Text('Selecciona un pedido en Inicio'));
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.repartidorData['nombre'] as String? ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $name'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [_buildHomeTab(), _buildPedidosTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'Pedidos'),
        ],
      ),
    );
  }
}

class PedidoDetalleScreen extends StatelessWidget {
  final String pedidoId;
  final Map<String, dynamic> pedidoData;

  const PedidoDetalleScreen(
      {Key? key, required this.pedidoId, required this.pedidoData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = pedidoData;
    final customerName =
        data['customerName'] as String? ?? 'Cliente';
    final customerPhone =
        data['customerPhone'] as String? ?? '';
    final customerAddress =
        data['customerAddress'] as String? ?? '';
    final status = data['status'] as String? ?? '—';
    final subtotal = data['subtotal'] as num? ?? 0;
    final envio = data['envio'] as num? ?? 0;
    final total = data['total'] as num? ?? 0;
    final items =
        (data['items'] as List).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: CircleAvatar(
              backgroundImage: NetworkImage(
                  data['customerPhoto'] ??
                      'https://via.placeholder.com/48')),
          title: Text('Pedido de: $customerName',
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Tel: $customerPhone'),
        ),
        const Divider(),
        Text('📍 Dirección Cliente: $customerAddress'),
        const SizedBox(height: 8),
        Text('📦 Estado: $status',
            style: const TextStyle(color: Colors.orange)),
        const SizedBox(height: 8),
        Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
        Text('Costo de Envío: \$${envio.toStringAsFixed(2)}'),
        Text('Total: \$${total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
        const Text('🍴 Platos:',
            style:
                TextStyle(fontWeight: FontWeight.bold)),
        ...items.map((it) => ListTile(
              leading: Image.network(it['imagenUrl'],
                  width: 48, height: 48, fit: BoxFit.cover),
              title: Text(it['nombre']),
              subtitle: Text(
                  'Precio: \$${it['precio']} x ${it['qty']}'),
            )),
      ],
    );
  }
}
