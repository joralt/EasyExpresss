// lib/categoria_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_detail_screen.dart';
import 'favorites_tab.dart';

class CategoriaScreen extends StatefulWidget {
  final String categoria;
  const CategoriaScreen({Key? key, required this.categoria}) : super(key: key);

  @override
  _CategoriaScreenState createState() => _CategoriaScreenState();
}

class _CategoriaScreenState extends State<CategoriaScreen> {
  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('LOCALES')
        .where('Categoria', isEqualTo: widget.categoria)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria, style: const TextStyle(color: Colors.black)),
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
            return const Center(child: Text('No hay locales en esta categoría'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc       = docs[i];
              final data      = doc.data()! as Map<String, dynamic>;
              final id        = doc.id;
              final nombre    = data['Nombre']    as String? ?? 'Sin nombre';
              final imagenUrl = data['Imagen']    as String? ?? '';
              final categoria = data['Categoria'] as String? ?? '';

              final isFavorito = FavoritosScreen.localesFavoritos
                  .any((loc) => loc['id'] == id);

              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocalDetailScreen(
                          localId:   id,
                          localName: nombre,
                        ),
                      ),
                    ),
                    child: Card(
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(categoria,
                                      style:
                                          const TextStyle(color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ❤️ Favorito
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFavorito) {
                            FavoritosScreen.localesFavoritos
                                .removeWhere((loc) => loc['id'] == id);
                          } else {
                            FavoritosScreen.localesFavoritos.add({
                              'id':        id,
                              'nombre':    nombre,
                              'imagenUrl': imagenUrl,
                              'categoria': categoria,
                            });
                          }
                        });
                      },
                      child: Icon(
                        isFavorito ? Icons.favorite : Icons.favorite_border,
                        color: isFavorito ? Colors.red : Colors.white,
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
