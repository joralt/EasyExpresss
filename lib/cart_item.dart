// lib/cart/cart_item.dart
class CartItem {
  final String nombre;
  final String imagenUrl;
  final double basePrice;
  int quantity;

  CartItem({
    required this.nombre,
    required this.imagenUrl,
    required this.basePrice,
    this.quantity = 1,
  });

  /// Suma un recargo de $0.50 por cada unidad extra
  double get totalCost => basePrice * quantity + 0.5 * (quantity - 1);
}
