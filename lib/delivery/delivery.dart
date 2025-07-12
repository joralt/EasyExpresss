// lib/delivery/delivery.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

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

  // Coordenadas iniciales de La Maná, Cotopaxi
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

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // El mapa
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _center,
            zoom: 15,
            onTap: (_, latlng) => setState(() => _markerPos = latlng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            if (_markerPos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _markerPos!,
                    width: 40,
                    height: 40,
                    builder: (_) => const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),
                  )
                ],
              ),
          ],
        ),

        // Botón de localizar
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.purple,
            onPressed: _locateMe,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Botón de iniciar / terminar jornada
        Positioned(
          bottom: 16,
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
            onPressed: () {
              setState(() => _jornadaActiva = !_jornadaActiva);
            },
          ),
        ),

        // Si la jornada está activa, mostramos los pedidos pendientes
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

                // Si no quedan pendientes...
                if (docs.isEmpty) {
                  // ...pero ya aceptó uno, mostramos mensaje con su nombre
                  if (_selectedOrderData != null) {
                    final cliente = _selectedOrderData!['customerName']
                        as String? ?? 'Cliente';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.yellow[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Tienes un pedido pendiente de $cliente',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  // ...sino, mensaje genérico
                  return const Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No hay pedidos pendientes'),
                    ),
                  );
                }

                // Sino, listado de pendientes
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                inProg ? Colors.grey : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: inProg
                              ? null
                              : () async {
                                  // 1) Actualizar en Firestore
                                  await _pedidosRef
                                      .doc(pedidoId)
                                      .update({'status': 'En curso'});
                                  // 2) Reflejar localmente y cambiar pestaña
                                  setState(() {
                                    _selectedOrderId = pedidoId;
                                    _selectedOrderData = {
                                      'id': pedidoId,
                                      ...data
                                    };
                                    _currentIndex = 1;
                                  });
                                },
                          child:
                              Text(inProg ? 'Pedido en curso' : 'Aceptar'),
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
        children: [
          _buildHomeTab(),
          _buildPedidosTab(),
        ],
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

/// Pantalla de detalle de pedido
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
    final locales = (data['locales'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

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
              subtitle: Text(
                  'Precio: \$${it['precio']} x ${it['qty']}  📍 Local: ${it['localName'] ?? ''}'),
            )),
      ],
    );
  }
}
