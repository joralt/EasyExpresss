// lib/cart/cart_screen.dart
import 'package:flutter/material.dart';
import '../orders_tab.dart'; // ajusta la ruta si fuera necesario

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  /// Lista estática que guarda los platos añadidos
  static List<Map<String, dynamic>> cartItems = [];

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _pedidoConfirmado = false;

  double get subtotal => CartScreen.cartItems.fold(
      0.0,
      (sum, item) =>
          sum + (item['precio'] as double) * (item['qty'] as int));

  @override
  Widget build(BuildContext context) {
    final items = CartScreen.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: items.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Expanded(child: _buildList(items)),
                _buildResumenYBotones(),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/car.png',
                width: 200, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega productos para verlos aquí.',
              style: TextStyle(fontSize: 14, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final it = items[i];
        final lineTotal =
            (it['precio'] as double) * (it['qty'] as int);
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: it['imagenUrl'] != ''
                ? Image.network(it['imagenUrl'],
                    width: 56, height: 56, fit: BoxFit.cover)
                : const SizedBox(width: 56, height: 56),
            title: Text(it['nombre']),
            subtitle: Text(
                '\$${it['precio'].toStringAsFixed(2)} x ${it['qty']} = \$${lineTotal.toStringAsFixed(2)}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() {
                CartScreen.cartItems.removeAt(i);
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumenYBotones() {
    // Envío base $1.25 + $0.50 extra por cada plato adicional
    final envio = 1.25 +
        (CartScreen.cartItems.length > 1
            ? 0.50 * (CartScreen.cartItems.length - 1)
            : 0.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtotal
          Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          // Envío
          Text('Envío: \$${envio.toStringAsFixed(2)}'),
          const Divider(height: 24, thickness: 1),
          // Total
          Text(
            'Total: \$${(subtotal + envio).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Botón Realizar / Confirmar
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _pedidoConfirmado ? Colors.orange : const Color(0xFF228B22),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _onRealizarOrConfirmar,
            child: Text(
              _pedidoConfirmado ? 'Confirmar Pedido' : 'Realizar Pedido',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _onRealizarOrConfirmar() {
    if (!_pedidoConfirmado) {
      // Paso 1: cambiar texto/color
      setState(() => _pedidoConfirmado = true);
      return;
    }

    // Paso 2: confirmar
    final order = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'En preparación',
      'date': DateTime.now(),
      'items': CartScreen.cartItems
          .map((it) => {
                'nombre': it['nombre'],
                'imagenUrl': it['imagenUrl'],
                'precio': it['precio'],
                'qty': it['qty'],
              })
          .toList(),
    };
    PedidosScreen.pedidosActuales.insert(0, order);

    // vaciar carrito y reset
    setState(() {
      CartScreen.cartItems.clear();
      _pedidoConfirmado = false;
    });

    // feedback al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Pedido confirmado! Puedes verlo en Mis pedidos.'),
      ),
    );
  }
}
