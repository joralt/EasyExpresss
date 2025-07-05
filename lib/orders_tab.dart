import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_detail_screen.dart';
import 'car.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({Key? key}) : super(key: key);

  /// Ahora guardamos Map completos en lugar de Strings
  static List<Map<String, dynamic>> pedidosActuales = [];
  static List<Map<String, dynamic>> historialPedidos  = [];

  @override
  _PedidosScreenState createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _cancelarPedido(int index) {
    final pedido = PedidosScreen.pedidosActuales.removeAt(index);
    pedido['status'] = 'Cancelado';
    PedidosScreen.historialPedidos.insert(0, pedido);
    setState(() {});
  }

  Widget _buildPedidoCard(
      Map<String, dynamic> pedido, bool isActual, int index) {
    final status = pedido['status'] as String;
    final id     = pedido['id']     as String;

    // leo el campo date de forma segura:
    final rawDate = pedido['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    final items = pedido['items'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Estado, ID y Fecha
              Text(
                'Estado: $status',
                style: TextStyle(
                  color: status == 'En preparación'
                      ? Colors.green
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Pedido ID: $id',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 2),
              Text(
                'Fecha: ${date.toLocal().toString().split('.').first}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),

              // Botón Cancelar Pedido (solo en actuales)
              if (isActual)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => _cancelarPedido(index),
                    child: const Text('Cancelar Pedido'),
                  ),
                ),
              if (isActual) const SizedBox(height: 8),

              const Divider(),

              // Lista de platos
              ...items.map<Widget>((it) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: it['imagenUrl'] != ''
                      ? Image.network(it['imagenUrl'],
                          width: 48, height: 48, fit: BoxFit.cover)
                      : const SizedBox(width: 48, height: 48),
                  title: Text(it['nombre']),
                  subtitle: Text(
                    '\$${(it['precio'] as double).toStringAsFixed(2)} x ${it['qty']}',
                  ),
                );
              }).toList(),
            ]),
      ),
    );
  }

  Widget _buildTab(List<Map<String, dynamic>> list, bool isActual) {
    if (list.isEmpty) {
      final asset = isActual ? 'assets/scooter.png' : 'assets/historial.png';
      final msg = isActual
          ? 'No tienes pedidos en curso'
          : 'Tu historial de pedidos está vacío';
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(asset, width: 200, height: 200, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => _buildPedidoCard(list[i], isActual, i),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(
                child: Text("Pedidos actuales",
                    style: TextStyle(color: Colors.black))),
            Tab(
                child: Text("Historial",
                    style: TextStyle(color: Colors.black54))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(PedidosScreen.pedidosActuales, true),
          _buildTab(PedidosScreen.historialPedidos, false),
        ],
      ),
    );
  }
}
