// lib/favorites_tab.dart
import 'package:flutter/material.dart';
import 'local_detail_screen.dart';

class FavoritosScreen extends StatefulWidget {
  static List<Map<String, String>> localesFavoritos   = [];
  static List<Map<String, String>> productosFavoritos = [];

  const FavoritosScreen({Key? key}) : super(key: key);
  @override
  _FavoritosScreenState createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildEmpty(String tipo) {
    final String img = tipo == 'local' ? 'assets/local.png' : 'assets/vacio.png';
    final String msg = tipo == 'local'
        ? 'No tienes locales favoritos aún'
        : 'No tienes productos favoritos aún';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(img, width: 200, height: 200, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLocalesGrid() {
    final list = FavoritosScreen.localesFavoritos;
    if (list.isEmpty) return _buildEmpty('local');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: .9
      ),
      itemBuilder: (_, i) {
        final m = list[i];
        return Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(children: [
            Positioned.fill(
              child: m['imagenUrl']!.isNotEmpty
                  ? Image.network(m['imagenUrl']!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade300),
            ),
            // Tap general para detalle
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LocalDetailScreen(
                        localId: m['id']!,
                        localName: m['nombre']!,
                      ),
                    ));
                  },
                ),
              ),
            ),
            // Corazón para desmarcar
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    FavoritosScreen.localesFavoritos.removeAt(i);
                  });
                },
                child: const Icon(Icons.favorite, color: Colors.red),
              ),
            ),
            // Nombre abajo
            Positioned(
              bottom: 8, left: 8, right: 8,
              child: Text(
                m['nombre']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius:4, color:Colors.black45)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildProductosGrid() {
    final list = FavoritosScreen.productosFavoritos;
    if (list.isEmpty) return _buildEmpty('producto');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: .9
      ),
      itemBuilder: (_, i) {
        final m = list[i];
        return Card(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(children: [
            Positioned.fill(
              child: m['imagenUrl']!.isNotEmpty
                  ? Image.network(m['imagenUrl']!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade300),
            ),
            // Tap general (por si quieres detalle de producto)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () {}),
              ),
            ),
            // Corazón para desmarcar
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    FavoritosScreen.productosFavoritos.removeAt(i);
                  });
                },
                child: const Icon(Icons.favorite, color: Colors.red),
              ),
            ),
            // Nombre y precio
            Positioned(
              bottom: 32, left: 8,
              child: Text(
                m['nombre']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows:[Shadow(blurRadius:4, color:Colors.black45)]
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              bottom: 8, left: 8,
              child: Text(
                '\$${m['precio']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows:[Shadow(blurRadius:4, color:Colors.black45)]
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(child: Text("Locales", style: TextStyle(color:Colors.black))),
            Tab(child: Text("Productos", style: TextStyle(color:Colors.black))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalesGrid(),
          _buildProductosGrid(),
        ],
      ),
    );
  }
}
