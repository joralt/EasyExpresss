import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final platosStream = FirebaseFirestore.instance
        .collection('LOCALES')
        .doc(localId)
        .collection('PLATOS')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localName,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: platosStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay platos disponibles'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final nombre      = data['nombre']      as String? ?? 'Sin nombre';
              final descripcion = data['descripcion'] as String? ?? '';
              final precio      = data['precio']      as num?    ?? 0;
              final imagenUrl   = data['imagen']      as String? ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  height: 100, // Altura fija para evitar layout infinito
                  child: Row(
                    children: [
                      // Imagen del plato
                      if (imagenUrl.isNotEmpty)
                        Image.network(
                          imagenUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Datos del plato
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Encoge al contenido
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descripcion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${precio.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
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
