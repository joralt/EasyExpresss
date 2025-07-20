// lib/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../orders_tab.dart'; // ajusta según tu estructura

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  /// Lista estática que guarda los platos añadidos
  static List<Map<String, dynamic>> cartItems = [];

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _confirmandoPedido = false;
  bool _pedidoEntregado   = false;

  double get subtotal => CartScreen.cartItems.fold(
        0.0,
        (sum, item) =>
            sum + (item['precio'] as double) * (item['qty'] as int),
      );

  Future<void> _onRealizarOrConfirmar() async {
    if (!_confirmandoPedido) {
      setState(() => _confirmandoPedido = true);
      return;
    }

    // 1) envío y ID
    final envio  = 1.25 + (CartScreen.cartItems.length > 1
        ? 0.50 * (CartScreen.cartItems.length - 1)
        : 0.0);
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    // 2) datos cliente
// ─── 2) datos cliente ───
final user    = FirebaseAuth.instance.currentUser!;
final uSnap   = await FirebaseFirestore.instance
    .collection('usuarios')
    .doc(user.uid)
    .get();
final udata   = uSnap.data()!;
// Extraemos coordenadas de usuario, si existen:
GeoPoint? customerCoords;
final rawCustLoc = udata['location'] ?? udata['coords'];
if (rawCustLoc is GeoPoint) {
  customerCoords = rawCustLoc;
} else if (rawCustLoc is Map) {
  final lat = rawCustLoc['lat'], lng = rawCustLoc['lng'];
  if (lat is num && lng is num) {
    customerCoords = GeoPoint(lat.toDouble(), lng.toDouble());
  }
}


    // 3) enriquecer cada plato con datos del local
    final enrichedItems = await Future.wait(
      CartScreen.cartItems.map((it) async {
        final localId = it['localId'] as String?;
        if (localId == null) {
          return {
            ...it,
            'localName'    : 'Desconocido',
            'localAddress' : '',
            'localCoords'  : null,
          };
        }
        final locSnap = await FirebaseFirestore.instance
            .collection('LOCALES')
            .doc(localId)
            .get();
        if (!locSnap.exists || locSnap.data() == null) {
          return {
            ...it,
            'localName'    : 'Desconocido',
            'localAddress' : '',
            'localCoords'  : null,
          };
        }
        final loc = locSnap.data()!;
        // ¡OJITO! matching exacto de campos en tu Firestore:
        final nameField    = loc['Nombre']      as String? ?? '';
        final addressField = loc['Ubicación']   as String? ?? '';
        final rawCoords    = loc['Coordenadas'];
        GeoPoint? coords;
        if (rawCoords is GeoPoint) {
          coords = rawCoords;
        } else if (rawCoords is Map) {
          final lat = rawCoords['lat'], lng = rawCoords['lng'];
          if (lat is num && lng is num) {
            coords = GeoPoint(lat.toDouble(), lng.toDouble());
          }
        }

        return {
          ...it,
          'localName'    : nameField,
          'localAddress' : addressField,
          'localCoords'  : coords,
        };
      }),
    );

    // 4) armar pedido
final orderData = {
  'id'              : orderId,
  'status'          : 'En preparación',
  'date'            : FieldValue.serverTimestamp(),
  'subtotal'        : subtotal,
  'envio'           : envio,
  'total'           : subtotal + envio,
  'items'           : enrichedItems,
  // datos del cliente
  'customerName'    : udata['displayName']  as String? ?? '',
  'customerEmail'   : udata['email']        as String? ?? '',
  'customerPhone'   : udata['phone']        as String? ?? '',
  'customerPhoto'   : udata['photoURL']     as String? ?? '',
  'customerAddress' : udata['address']      as String? ?? '',
  'customerCoords'  : customerCoords,        // ← aquí
};


    // 5) guardar
    await FirebaseFirestore.instance
        .collection('PEDIDOS')
        .doc(orderId)
        .set(orderData);

    // 6) limpio y confirmo
    setState(() {
      CartScreen.cartItems.clear();
      _confirmandoPedido = false;
      _pedidoEntregado   = true;
    });
  }

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

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/car.png',
                  width: 200, height: 200, fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Text('Tu carrito está vacío',
                  style: TextStyle(fontSize: 18, color: Colors.black54)),
              const SizedBox(height: 12),
              const Text('Agrega productos para verlos aquí.',
                  style: TextStyle(fontSize: 14, color: Colors.black45)),
            ],
          ),
        ),
      );

  Widget _buildList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final it        = items[i];
        final lineTotal = (it['precio'] as double) * (it['qty'] as int);
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
              onPressed: () => setState(() => CartScreen.cartItems.removeAt(i)),
            ),
          ),
        );
      },
    );
  }

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
          Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          Text('Envío: \$${envio.toStringAsFixed(2)}'),
          const Divider(height: 24, thickness: 1),
          Text('Total: \$${(subtotal + envio).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _confirmandoPedido ? Colors.orange : const Color(0xFF228B22),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildConfirmacion() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('¡Pedido confirmado!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Puedes verlo en Mis pedidos.',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF228B22),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PedidosScreen()),
              ),
              child: const Text('Ver Mis Pedidos', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}
