// lib/orders_tab.dart  (o favorites_tab.dart según tu estructura)
import 'package:flutter/material.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({Key? key}) : super(key: key);

  // Lista estática para compartir entre pantallas
  static List<String> pedidosActuales = [];
  static List<String> historialPedidos  = [];

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

  Widget buildVacio({required String tipo}) {
    final rutaImagen = tipo == 'actual' ? 'assets/scooter.png' : 'assets/historial.png';
    final mensaje = tipo == 'actual'
        ? 'No tienes pedidos en curso'
        : 'Tu historial de pedidos está vacío';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(rutaImagen, width: 200, height: 200, fit: BoxFit.contain),
          const SizedBox(height: 20),
          Text(mensaje, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget buildListaPedidos(List<String> pedidos, String tipo) {
    if (pedidos.isEmpty) return buildVacio(tipo: tipo);
    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, i) {
        return ListTile(
          leading: Icon(tipo == 'actual' ? Icons.delivery_dining : Icons.receipt_long),
          title: Text(pedidos[i]),
          subtitle: Text(tipo == 'actual'
              ? 'En preparación o camino'
              : 'Entregado correctamente'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(child: Text("Pedidos actuales", style: TextStyle(color: Colors.black))),
            Tab(child: Text("Historial",       style: TextStyle(color: Colors.black))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListaPedidos(PedidosScreen.pedidosActuales, 'actual'),
          buildListaPedidos(PedidosScreen.historialPedidos, 'historial'),
        ],
      ),
    );
  }
}
