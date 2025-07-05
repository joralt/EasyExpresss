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
  bool _confirmandoPedido = false;
  bool _pedidoEntregado  = false;

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
      body: _pedidoEntregado
          ? _buildConfirmacion()
          : items.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    Expanded(child: _buildList(items)),
                    _buildResumenYBotones(),
                  ],
                ),
    );
  }

  /// Vista de carrito vacío
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

  /// Lista de productos en el carrito
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

  /// Resumen y botones de acción
  Widget _buildResumenYBotones() {
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
                  _confirmandoPedido ? Colors.orange : const Color(0xFF228B22),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _onRealizarOrConfirmar,
            child: Text(
              _confirmandoPedido ? 'Confirmar Pedido' : 'Realizar Pedido',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Mensaje de confirmación con icono de check verde
  Widget _buildConfirmacion() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text(
            '¡Pedido confirmado!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes verlo en Mis pedidos.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF228B22),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // navegar a PedidosScreen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PedidosScreen()),
              );
            },
            child: const Text('Ver Mis Pedidos',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Lógica de Realizar / Confirmar Pedido
  void _onRealizarOrConfirmar() {
    if (!_confirmandoPedido) {
      // primer click → cambiar texto/color
      setState(() => _confirmandoPedido = true);
      return;
    }

    // segundo click → crear el pedido
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

    // limpiar
    setState(() {
      CartScreen.cartItems.clear();
      _confirmandoPedido = false;
      _pedidoEntregado  = true;
    });
  }
}
