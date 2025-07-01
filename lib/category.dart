import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_detail_screen.dart';

class CategoriaScreen extends StatelessWidget {
  final String categoria;
  const CategoriaScreen({Key? key, required this.categoria}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('LOCALES')
        .where('Categoria', isEqualTo: categoria)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoria, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay locales en esta categoría'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data      = docs[i].data() as Map<String, dynamic>;
              final nombre    = data['Nombre']    as String? ?? 'Sin nombre';
              final imagenUrl = data['Imagen']    as String? ?? '';
              final categoria = data['Categoria'] as String? ?? '';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocalDetailScreen(
                      localId: docs[i].id,
                      localName: nombre,
                    ),
                  ),
                ),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: imagenUrl.isNotEmpty
                            ? Image.network(imagenUrl, width: 100, height: 100, fit: BoxFit.cover)
                            : Container(
                                width: 100, height: 100, color: Colors.grey.shade300),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(categoria,
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
