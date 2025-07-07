// lib/delivery/delivery.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class RepartidorApp extends StatefulWidget {
  final Map<String, dynamic> repartidorData;
  const RepartidorApp({Key? key, required this.repartidorData})
      : super(key: key);

  @override
  State<RepartidorApp> createState() => _RepartidorAppState();
}

class _RepartidorAppState extends State<RepartidorApp> {
  int _currentIndex = 0;
  Map<String, dynamic>? _selectedOrder;
  final _pedidosRef = FirebaseFirestore.instance.collection('PEDIDOS');

  // Coordenadas de La Maná, Cotopaxi
  LatLng _center = LatLng(-0.9337, -79.2044);
  LatLng? _markerPos;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, 15);
    });
  }

  Future<void> _locateMe() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa tu GPS')));
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

  Widget _buildHomeTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _center,
            zoom: 15,
            onTap: (_, latlng) => setState(() => _markerPos = latlng),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a','b','c'],
            ),
            if (_markerPos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPos!,
                    width: 40, height: 40,
                    builder: (_) => const Icon(Icons.location_on,
                      size: 40, color: Colors.red),
                  )
                ],
              ),
          ],
        ),
        Positioned(
          top: 16, right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.purple,
            onPressed: _locateMe,
            child: const Icon(Icons.my_location),
          ),
        ),
        // ❗ Pedidos pendientes pequeñas tarjetas
        Positioned(
          top: 80, left: 16, right: 16,
          child: StreamBuilder<QuerySnapshot>(
            stream: _pedidosRef
              .where('status', isEqualTo: 'En preparación')
              .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              final docs = snap.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  final email = data['customerEmail'] as String? ?? '—';
                  final status = data['status'] as String? ?? '—';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text('Pedido de $email'),
                      subtitle: Text('Estado: $status'),
                      trailing: TextButton(
                        onPressed: () {
                          // Al aceptar, guardo y cambio a pestaña "Pedidos"
                          setState(() {
                            _selectedOrder = {
                              'id': doc.id,
                              ...data,
                            };
                            _currentIndex = 1;
                          });
                        },
                        child: const Text('Aceptar'),
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
    // Si acabo de aceptar uno, muestro el detalle:
    if (_selectedOrder != null) {
      return PedidoDetalleScreen(
        pedidoId: _selectedOrder!['id'] as String,
        pedidoData: _selectedOrder!,
      );
    }
    // En otro caso, lista histórica (o vacía)
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
        children: [
          _buildHomeTab(),
          _buildPedidosTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _currentIndex = i;
        }),
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

/// Pantalla de detalle de pedido (igual que antes)
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
    final items = (data['items'] as List)
        .cast<Map<String, dynamic>>();
    final locales = (data['locales'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              data['customerPhoto'] ??
              'https://via.placeholder.com/48'),
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
              subtitle: Text(
                  'Precio: \$${it['precio']} x ${it['qty']}  📍 Local: ${it['localName'] ?? ''}'),
            )),
      ],
    );
  }
}
