import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PedidosScreen extends StatefulWidget {
  @override
  _PedidosScreenState createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildVacio({required String tipo}) {
    final String rutaImagen = tipo == 'actual' ? 'assets/scooter.png' : 'assets/historial.png';
    final String mensaje = tipo == 'actual' ? 'No tienes pedidos en curso' : 'Tu historial de pedidos está vacío';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(rutaImagen, width: 200, height: 200, fit: BoxFit.contain),
          const SizedBox(height: 20),
          Text(mensaje, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget buildListaPedidos(bool isHistory) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Inicia sesión para ver tus pedidos'));

    final query = FirebaseFirestore.instance
        .collection('PEDIDOS')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: isHistory ? 'Entregado' : 'Pendiente')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return buildVacio(tipo: isHistory ? 'historial' : 'actual');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final items = (data['items'] as List? ?? []);
            final total = data['total'] ?? 0.0;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr = createdAt != null ? DateFormat('dd/MM HH:mm').format(createdAt) : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: (isHistory ? Colors.grey : Colors.green).withOpacity(0.1),
                  child: Icon(isHistory ? Icons.check_circle_outline : Icons.local_shipping, color: isHistory ? Colors.grey : Colors.green),
                ),
                title: Text('Pedido # ${docs[index].id.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${items.length} productos • $dateStr', style: const TextStyle(fontSize: 12)),
                    Text(items.map((i) => i['nombre']).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mis Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "En curso"),
            Tab(text: "Historial"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildListaPedidos(false),
          buildListaPedidos(true),
        ],
      ),
    );
  }
}