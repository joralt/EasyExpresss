// lib/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'orders_tab.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  static List<Map<String, dynamic>> cartItems = [];

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _showConfirmButton = false;
  bool _pedidoCompletado = false;

  double get subtotal => CartScreen.cartItems.fold(
        0.0,
        (sum, item) => sum + (item['precio'] as double) * (item['qty'] as int),
      );
  static const double shippingBase = 1.25;
  double get shipping {
    final totalQty =
        CartScreen.cartItems.fold(0, (sum, item) => sum + (item['qty'] as int));
    if (totalQty <= 1) return shippingBase;
    return shippingBase + (totalQty - 1) * 0.5;
  }

  void _onRealizarPedido() {
    setState(() {
      _showConfirmButton = true;
    });
  }

  void _onConfirmarPedido() {
    // Construimos un resumen y lo enviamos a PedidosScreen
    final desc = CartScreen.cartItems
        .map((it) => "${it['qty']}× ${it['nombre']}")
        .join(", ");
    PedidosScreen.pedidosActuales.add(desc);

    setState(() {
      _pedidoCompletado = true;
      CartScreen.cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pedidoCompletado) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carrito'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text('¡Pedido completado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Puedes verlo en Mis Pedidos'),
            ],
          ),
        ),
      );
    }

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
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final lineTotal = (it['precio'] as double) * (it['qty'] as int);
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: it['imagenUrl'] != ''
                              ? Image.network(it['imagenUrl'], width: 56, height: 56, fit: BoxFit.cover)
                              : const SizedBox(width: 56, height: 56),
                          title: Text(it['nombre']),
                          subtitle: Text('\$${it['precio'].toStringAsFixed(2)} × ${it['qty']} = \$${lineTotal.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => CartScreen.cartItems.removeAt(i)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Text('Envío: \$${shipping.toStringAsFixed(2)}'),
                      const Divider(height: 32),
                      Text('Total: \$${(subtotal + shipping).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),

                      // ─── Botones encadenados ───────────────────────────
                      if (!_showConfirmButton)
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF228B22),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: _onRealizarPedido,
                            child: const Text('Realizar Pedido', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        )
                      else
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: _onConfirmarPedido,
                            child: const Text('Confirmar Pedido', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
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
            Image.asset('assets/car.png', width: 200, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Text('Tu carrito está vacío', style: TextStyle(fontSize: 18, color: Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('Agrega productos para verlos aquí.', style: TextStyle(fontSize: 14, color: Colors.black45), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
