import 'package:flutter/material.dart';

class FavoritosScreen extends StatefulWidget {
  @override
  _FavoritosScreenState createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> localesFavoritos = []; // Vacío = muestra imagen
  List<String> productosFavoritos = []; // Vacío = muestra imagen

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget buildVacio({required String tipo}) {
    final String rutaImagen = tipo == 'local'
        ? 'assets/local.png'
        : 'assets/vacio.png';

    final String mensaje = tipo == 'local'
        ? 'No tienes locales favoritos aún'
        : 'No tienes productos favoritos aún';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            rutaImagen,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            mensaje,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildLista(List<String> items, String tipo) {
    if (items.isEmpty) return buildVacio(tipo: tipo);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
          subtitle: tipo == 'local' ? const Text('Dirección del local') : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(child: Text("Locales", style: TextStyle(color: Colors.black))),
            Tab(child: Text("Productos", style: TextStyle(color: Colors.black))),
          ],
          indicatorColor: Colors.green,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildLista(localesFavoritos, 'local'),
          buildLista(productosFavoritos, 'producto'),
        ],
      ),
    );
  }
}