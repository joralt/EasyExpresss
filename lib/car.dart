// lib/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../orders_tab.dart'; // ajusta la ruta según tu proyecto

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
    // 1er tap: cambio de estado del botón
    if (!_confirmandoPedido) {
      setState(() => _confirmandoPedido = true);
      return;
    }

    // 2º tap: confirmación → arma el pedido
    final envio  = 1.25 +
        (CartScreen.cartItems.length > 1
            ? 0.50 * (CartScreen.cartItems.length - 1)
            : 0.0);
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    // ─── 1) Lee datos del cliente ───
    final user     = FirebaseAuth.instance.currentUser!;
    final userSnap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final udata    = userSnap.data() ?? {};

    // ─── 2) Enriquecer cada plato con datos reales del local ───
    final enrichedItems = await Future.wait(
      CartScreen.cartItems.map((it) async {
        final localId = it['localId'] as String?;
        if (localId == null) {
          // Si no tienes localId, devuelves un placeholder
          return {
            ...it,
            'localName'    : 'Desconocido',
            'localAddress' : '',
            'localCoords'  : null,
          };
        }

        // ¡LEER DEL DOC PADRE de LOCALES, no de la subcolección!
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

        // Ajusta estos nombres al esquema real de tu Firestore:
        final addressField = loc['Ubicación'] ?? loc['ubicacion'] ?? '';
        final geoRaw       = loc['Coordenadas'] ?? loc['coordenadas'] ?? loc['location'];

        GeoPoint? coords;
        if (geoRaw is GeoPoint) {
          coords = geoRaw;
        } else if (geoRaw is Map<String, dynamic>) {
          final lat = geoRaw['lat'], lng = geoRaw['lng'];
          if (lat is num && lng is num) {
            coords = GeoPoint(lat.toDouble(), lng.toDouble());
          }
        }

        return {
          ...it,
          'localName'    : loc['Nombre']      ?? '',
          'localAddress' : addressField as String,
          'localCoords'  : coords,
        };
      }),
    );

    // ─── 3) Construir el mapa final del pedido ───
    final orderData = {
      'id'             : orderId,
      'status'         : 'En preparación',
      'date'           : FieldValue.serverTimestamp(),
      'subtotal'       : subtotal,
      'envio'          : envio,
      'total'          : subtotal + envio,
      'items'          : enrichedItems,
      // Datos del cliente
      'customerName'   : udata['displayName']    ?? '',
      'customerEmail'  : udata['email']          ?? '',
      'customerPhone'  : udata['phone']          ?? '',
      'customerPhoto'  : udata['photoURL']       ?? '',
      'customerAddress': udata['address']        ?? '',
    };

    // ─── 4) Guardar en Firestore ───
    await FirebaseFirestore.instance
        .collection('PEDIDOS')
        .doc(orderId)
        .set(orderData);

    // ─── 5) Limpiar carrito y mostrar confirmación ───
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
              onPressed: () => setState(
                () => CartScreen.cartItems.removeAt(i),
              ),
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
          Text(
            'Total: \$${(subtotal + envio).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _confirmandoPedido
                  ? Colors.orange
                  : const Color(0xFF228B22),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PedidosScreen()),
            ),
            child: const Text('Ver Mis Pedidos',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
