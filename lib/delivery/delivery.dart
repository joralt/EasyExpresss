import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({Key? key}) : super(key: key);

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng _center = LatLng(-0.1807, -78.4678); // Quito por defecto

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _locateMe();
  }

  Future<void> _locateMe() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Panel de Repartidor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF228B22),
          labelColor: const Color(0xFF228B22),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Disponibles"),
            Tab(text: "Mis entregas"),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Mapa de fondo
          FlutterMap(
            options: MapOptions(
              center: _center,
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                additionalOptions: const {
                  'userAgent': 'com.example.easyexpres',
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 40,
                    height: 40,
                    builder: (ctx) => const Icon(Icons.my_location, color: Color(0xFF228B22), size: 30),
                  ),
                ],
              ),
            ],
          ),
          
          // Contenido superpuesto
          Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsRow(),
              ),
              const Expanded(
                child: SizedBox(),
              ),
              // Panel inferior deslizable (Simulado con fondo blanco)
              Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF228B22),
                      labelColor: const Color(0xFF228B22),
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Disponibles"),
                        Tab(text: "Mis entregas"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrdersList(isAvailable: true, withStats: false),
                          _buildOrdersList(isAvailable: false, withStats: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF228B22),
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text('Actualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOrdersList({required bool isAvailable, bool withStats = true}) {
    // Placeholder para la lista de pedidos
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (withStats) ...[
          _buildStatsRow(),
          const SizedBox(height: 24),
        ],
        if (isAvailable) ...[
          _buildOrderCard(
            id: 'ORD-7642',
            store: 'Pizzería La Mamma',
            distance: '1.2 km',
            payment: '\$15.50',
            fee: '\$1.75',
          ),
          _buildOrderCard(
            id: 'ORD-7645',
            store: 'Burger House',
            distance: '2.5 km',
            payment: '\$22.00',
            fee: '\$2.25',
          ),
        ] else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No tienes entregas activas', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Balance Hoy', '\$12.50', Icons.account_balance_wallet_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Entregas', '5', Icons.check_circle_outline)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF228B22), size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String id,
    required String store,
    required String distance,
    required String payment,
    required String fee,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Nuevo', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF228B22).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF228B22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Distancia: $distance', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(payment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Total orden', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tu ganancia', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(fee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF228B22))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
