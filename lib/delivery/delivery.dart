// lib/delivery/delivery.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepartidorApp extends StatefulWidget {
  final Map<String, dynamic> repartidorData;
  const RepartidorApp({Key? key, required this.repartidorData})
      : super(key: key);

  @override
  State<RepartidorApp> createState() => _RepartidorAppState();
}

class _RepartidorAppState extends State<RepartidorApp> {
  int _currentIndex = 0;
  final _pedidosRef = FirebaseFirestore.instance.collection('PEDIDOS');

  @override
  Widget build(BuildContext context) {
    final name   = widget.repartidorData['nombre']   as String? ?? '';
    final cedula = widget.repartidorData['cedula']   as String? ?? '';
    final phone  = widget.repartidorData['telefono'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $name'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cédula: $cedula'),
            Text('Teléfono: $phone'),
            const SizedBox(height: 24),
            const Text(
              'Pedidos pendientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _pedidosRef
                    .where('status', isEqualTo: 'Pendiente')  // ahora sí coincide
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay pedidos pendientes'));
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data()! as Map<String, dynamic>;
                      final email = data['customerEmail'] as String? ?? '—';
                      final status = data['status'] as String? ?? '—';

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: ListTile(
                            title: Text('Pedido de $email',
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Estado: $status'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                // TODO: lógica de aceptar pedido
                              },
                              child: const Text('Aceptar'),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
