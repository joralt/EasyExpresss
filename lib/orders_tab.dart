import 'package:flutter/material.dart';

class PedidosScreen extends StatefulWidget {
  @override
  _PedidosScreenState createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Listas simuladas
  List<String> pedidosActuales = []; // pedidos en curso
  List<String> historialPedidos = []; // pedidos completados

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget buildVacio({required String tipo}) {
    final String rutaImagen = tipo == 'actual'
        ? 'assets/scooter.png'
        : 'assets/historial.png';

    final String mensaje = tipo == 'actual'
        ? 'No tienes pedidos en curso'
        : 'Tu historial de pedidos está vacío';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            rutaImagen,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            mensaje,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildListaPedidos(List<String> pedidos, String tipo) {
    if (pedidos.isEmpty) return buildVacio(tipo: tipo);

    return ListView.builder(
      itemCount: pedidos.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(tipo == 'actual' ? Icons.delivery_dining : Icons.receipt_long),
          title: Text(pedidos[index]),
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
          tabs: const [
            Tab(child: Text("Pedidos actuales", style: TextStyle(color: Colors.black))),
            Tab(child: Text("Historial", style: TextStyle(color: Colors.black))),
          ],
          indicatorColor: Colors.green,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListaPedidos(pedidosActuales, 'actual'),
          buildListaPedidos(historialPedidos, 'historial'),
        ],
      ),
    );
  }
}