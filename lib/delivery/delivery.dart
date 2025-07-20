import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart'; // NetworkTileProvider, PolylineLayer
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class RepartidorApp extends StatefulWidget {
  final Map<String, dynamic> repartidorData;
  const RepartidorApp({Key? key, required this.repartidorData})
      : super(key: key);

  @override
  State<RepartidorApp> createState() => _RepartidorAppState();
}

class _RepartidorAppState extends State<RepartidorApp> {
  int _currentIndex = 0;
  bool _jornadaActiva = false;
  String? _selectedOrderId;
  Map<String, dynamic>? _selectedOrderData;
  final _pedidosRef = FirebaseFirestore.instance.collection('PEDIDOS');

  LatLng _center = LatLng(-0.9337, -79.2044);
  LatLng? _markerPos;
  final _mapController = MapController();
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _mapController.move(_center, 15));
  }

  Future<void> _locateMe() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Activa tu GPS')));
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
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  Widget _buildHomeTab() {
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
                  'Referer': 'https://tudominio.com/',
                }),
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: _routePoints, strokeWidth: 4),
                ]),
              MarkerLayer(markers: [
                if (_markerPos != null)
                  Marker(
                    point: _markerPos!,
                    width: 40,
                    height: 40,
                    builder: (_) => const Icon(
                      Icons.person_pin_circle,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                for (var loc in rawLocales(_selectedOrderData))
                  Marker(
                    point: loc,
                    width: 30,
                    height: 30,
                    builder: (_) =>
                        const Icon(Icons.store, size: 30, color: Colors.green),
                  ),
                if (_selectedOrderData?['0'] != null &&
                    _selectedOrderData?['1'] != null)
                  Marker(
                    point: LatLng(
                      (_selectedOrderData!['0'] as num).toDouble(),
                      (_selectedOrderData!['1'] as num).toDouble(),
                    ),
                    width: 35,
                    height: 35,
                    builder: (_) =>
                        const Icon(Icons.home, size: 35, color: Colors.red),
                  ),
              ]),
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
            label:
                Text(_jornadaActiva ? 'Terminar jornada' : 'Iniciar jornada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _jornadaActiva ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => setState(() => _jornadaActiva = !_jornadaActiva),
          ),
        ),
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
                    final pedidoId = doc.id;
                    final inProg = pedidoId == _selectedOrderId;
                    final email = data['customerEmail'] as String? ?? 'Cliente';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text('Pedido de $email'),
                        subtitle: Text(
                            'Estado: ${inProg ? 'En curso' : data['status']}'),
                        trailing: ElevatedButton(
                          onPressed: inProg
                              ? null
                              : () async {
                                  // marco pedido en curso
                                  await _pedidosRef
                                      .doc(pedidoId)
                                      .update({'status': 'En curso'});
                                  setState(() {
                                    _selectedOrderId = pedidoId;
                                    _selectedOrderData = {
                                      'id': pedidoId,
                                      ...data
                                    };
                                  });
                                  // obtengo lat/lng de cliente
                                  final lat = data['0'] as num?;
                                  final lng = data['1'] as num?;
                                  if (lat == null || lng == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Coordenadas cliente faltantes'),
                                      ),
                                    );
                                    return;
                                  }
                                  final destino = LatLng(
                                      lat.toDouble(), lng.toDouble());
                                  // calculo ruta carretera
                                  final origen = _markerPos ?? _center;
                                  final road = await _fetchRoadRoute(
                                      origen, destino);
                                  setState(() => _routePoints = road);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                inProg ? Colors.grey : Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(inProg ? 'En curso' : 'Aceptar'),
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
    return const Center(child: Text('Selecciona un pedido en Inicio'));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.repartidorData['nombre'] as String? ?? '';
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
        ],
      ),
    );
  }
}

List<LatLng> rawLocales(Map<String, dynamic>? orderData) {
  final raw = orderData?['locales'] as List<dynamic>? ?? [];
  return raw.cast<Map<String, dynamic>>().map((loc) {
    final lc = loc['localCoords'] as List<dynamic>;
    return LatLng((lc[0] as num).toDouble(), (lc[1] as num).toDouble());
  }).toList();
}

class PedidoDetalleScreen extends StatelessWidget {
  final String pedidoId;
  final Map<String, dynamic> pedidoData;

  const PedidoDetalleScreen({
    Key? key,
    required this.pedidoId,
    required this.pedidoData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = pedidoData;
    final customerName = data['customerName'] as String? ?? 'Cliente';
    final customerPhone = data['customerPhone'] as String? ?? '';
    final customerAddress = data['customerAddress'] as String? ?? '';
    final status = data['status'] as String? ?? '—';
    final subtotal = data['subtotal'] as num? ?? 0;
    final envio = data['envio'] as num? ?? 0;
    final total = data['total'] as num? ?? 0;
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    final locales = (data['locales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              data['customerPhoto'] ?? 'https://via.placeholder.com/48',
            ),
          ),
          title: Text('Pedido de: $customerName',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
        const Text('📍 Locales de Recogida:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...locales.map((loc) => ListTile(
              leading: const Icon(Icons.store, color: Colors.blue),
              title: Text(loc['nombre'] ?? ''),
              subtitle: Text('Ubicación: ${loc['direccion'] ?? ''}'),
            )),
        const Divider(),
        const Text('🍴 Platos:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...items.map((it) => ListTile(
              leading: Image.network(it['imagenUrl'],
                  width: 48, height: 48, fit: BoxFit.cover),
              title: Text(it['nombre']),
              subtitle: Text('Precio: \$${it['precio']} x ${it['qty']}'),
            )),
      ],
    );
  }
}
