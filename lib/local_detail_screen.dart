// lib/local_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favorites_tab.dart';
import 'car.dart';

class LocalDetailScreen extends StatelessWidget {
  final String localId;
  final String localName;
  const LocalDetailScreen({
    Key? key,
    required this.localId,
    required this.localName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('LOCALES')
        .doc(localId)
        .collection('PLATOS')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(localName, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('No hay platos'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data      = docs[i].data()! as Map<String, dynamic>;
              final nombre    = data['nombre'] as String? ?? 'Sin nombre';
              final desc      = data['descripcion'] as String? ?? '';
              final precio    = (data['precio'] ?? 0).toDouble();
              final imagenUrl = data['imagen']   as String? ?? '';

              final isFavorito = FavoritosScreen.productosFavoritos
                  .any((p) => p['nombre'] == nombre);

              return Stack(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.hardEdge,
                    child: Row(
                      children: [
                        if (imagenUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12)),
                            child: Image.network(imagenUrl,
                                width: 100, height: 100, fit: BoxFit.cover),
                          )
                        else
                          Container(
                            width: 100, height: 100, color: Colors.grey.shade300),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(desc,
                                    style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text('\$${precio.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ❤️ Favorito
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (isFavorito) {
                          FavoritosScreen.productosFavoritos
                              .removeWhere((p) => p['nombre'] == nombre);
                        } else {
                          FavoritosScreen.productosFavoritos.add({
                            'nombre':    nombre,
                            'imagenUrl': imagenUrl,
                            'precio':    precio.toStringAsFixed(2),
                          });
                        }
                        (context as Element).markNeedsBuild();
                      },
                      child: Icon(
                        isFavorito ? Icons.favorite : Icons.favorite_border,
                        color: isFavorito ? Colors.red : Colors.white,
                      ),
                    ),
                  ),

                  // ➕ Añadir al carrito
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        CartScreen.cartItems.add({
                          'nombre':    nombre,
                          'imagenUrl': imagenUrl,
                          'precio':    precio,
                          'qty':       1,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Producto añadido')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
