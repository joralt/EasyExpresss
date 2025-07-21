import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F35A5), // Color de fondo similar a la app
        title: Column(
          children: [
            const Text(
              'Detalle del Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Pedido de: $customerName',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                    data['customerPhoto'] ?? 'https://via.placeholder.com/48'),
              ),
              title: Text(
                'Pedido de: $customerName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Tel: $customerPhone'),
            ),
            const Divider(),
            Text('📍 Dirección Cliente: $customerAddress'),
            const SizedBox(height: 8),
            Text(
              '📦 Estado: $status',
              style: const TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
            Text('Costo de Envío: \$${envio.toStringAsFixed(2)}'),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text(
              '🍴 Platos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...items.map(
              (it) => ListTile(
                leading: Image.network(
                  it['imagenUrl'],
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
                title: Text(it['nombre']),
                subtitle: Text('Precio: \$${it['precio']} x ${it['qty']}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
