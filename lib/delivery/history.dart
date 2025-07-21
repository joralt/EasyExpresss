import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({Key? key}) : super(key: key);

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  final _pedidosRef = FirebaseFirestore.instance.collection('PEDIDOS');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        backgroundColor: const Color(0xFF6F35A5),
        centerTitle: true,
                automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pedidosRef
            .where('status', isEqualTo: 'Entregado') // Filtra los pedidos entregados
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tienes pedidos en el historial.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final customerName = data['customerName'] ?? 'Cliente';
              final customerPhone = data['customerPhone'] ?? '';
              final status = data['status'] ?? '—';
              final items = (data['items'] as List).cast<Map<String, dynamic>>();
              final total = data['total'] as num? ?? 0;
              final date = (data['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Pedido de $customerName',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Tel: $customerPhone'),
                        trailing: Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Fecha: ${date.toLocal().toString().split('.').first}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estado: $status',
                        style: TextStyle(
                          color: status == 'Entregado' ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      const Text('🍴 Platos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((it) => ListTile(
                            leading: Image.network(
                              it['imagenUrl'],
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                            title: Text(it['nombre']),
                            subtitle: Text('Precio: \$${it['precio']} x ${it['qty']}'),
                          )),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
