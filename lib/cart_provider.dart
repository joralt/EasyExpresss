import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    this.cantidad = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity {
    var total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.cantidad;
    });
    return total;
  }

  double get shippingCost {
    if (_items.isEmpty) return 0.0;
    const baseShipping = 1.75;
    final extraPlates = totalQuantity > 2 ? totalQuantity - 2 : 0;
    return baseShipping + (extraPlates * 0.50);
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.precio * cartItem.cantidad;
    });
    return total + shippingCost;
  }

  void addItem(String productId, String nombre, double precio, String imagenUrl) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          nombre: existing.nombre,
          precio: existing.precio,
          imagenUrl: existing.imagenUrl,
          cantidad: existing.cantidad + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: DateTime.now().toString(),
          nombre: nombre,
          precio: precio,
          imagenUrl: imagenUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.cantidad > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          nombre: existing.nombre,
          precio: existing.precio,
          imagenUrl: existing.imagenUrl,
          cantidad: existing.cantidad - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<void> confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _items.isEmpty) return;

    final orderData = {
      'userId': user.uid,
      'userName': user.displayName,
      'userEmail': user.email,
      'items': _items.values.map((i) => {
        'nombre': i.nombre,
        'precio': i.precio,
        'cantidad': i.cantidad,
      }).toList(),
      'shippingCost': shippingCost,
      'subtotal': totalAmount - shippingCost,
      'total': totalAmount,
      'status': 'Pendiente',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('PEDIDOS').add(orderData);
    clearCart();
  }
}
