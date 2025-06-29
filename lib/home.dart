import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_detail_screen.dart';
import 'favorites_tab.dart';
import 'orders_tab.dart';
import 'account/account_tab.dart';
import 'car.dart';
import 'notification.dart';
import 'category.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
              FavoritosScreen(),
              PedidosScreen(),
              AccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF228B22),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final name     = widget.userData['Nombres']   as String? ?? 'Usuario';
    final address  = widget.userData['Direccion'] as String? ?? '';
    final photoUrl = widget.userData['Foto']      as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: (photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, $name',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(address,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CartScreen()));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // BÚSQUEDA
          _buildSearchBar(),

          const SizedBox(height: 16),

          // PROMOCIONES
          _buildPromotionCarousel(),

          const SizedBox(height: 24),

          // CATEGORÍAS
          _buildSectionTitle('Categorías'),
          _buildCategories(),

          const SizedBox(height: 24),

          // LOCALES
          _buildSectionTitle('Locales cerca de ti'),
          const SizedBox(height: 12),
          _buildLocalesSlider(),

          const SizedBox(height: 24),

          // RECOMENDADO
          _buildSectionTitle('Recomendado para ti'),
          const SizedBox(height: 12),
          _buildPlatosRecomendados(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar local, comida o producto…',
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Color(0xFFF0F0F0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _buildPromotionCarousel() => SizedBox(
        height: 150,
        child: PageView.builder(
          itemCount: 3,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade300,
            ),
            child: Center(
              child: Text('Promo ${i + 1}',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

Widget _buildCategories() {
  final categories = [
    {'icon': 'assets/restaurante.png', 'label': 'Restaurantes'},
    {'icon': 'assets/rapida.png',       'label': 'Rápida'},
    {'icon': 'assets/piocanteria.png',  'label': 'Picanterías'},
    {'icon': 'assets/tienda.png',       'label': 'Tiendas'},
    {'icon': 'assets/farmacia.png',     'label': 'Farmacias'},
    {'icon': 'assets/heladeria.png',    'label': 'Heladerías'},
    {'icon': 'assets/licor.png',        'label': 'Licorerías'},
  ];

  return Padding(
    padding: const EdgeInsets.only(left: 16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoriaScreen(
                      categoria: cat['label']!,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: ClipOval(
                      child: Image.asset(cat['icon']!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(cat['label']!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}


  Widget _buildLocalesSlider() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('LOCALES').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay locales disponibles'));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data      = docs[i].data() as Map<String, dynamic>;
              final nombre    = data['Nombre']    as String? ?? 'Sin nombre';
              final categoria = data['Categoria'] as String? ?? '';
              final imagenUrl = data['Imagen']    as String? ?? '';

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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: imagenUrl.isNotEmpty
                                ? Image.network(imagenUrl, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade300),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(categoria,
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlatosRecomendados() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('PLATOS')
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay recomendaciones'));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data       = docs[i].data() as Map<String, dynamic>;
              final nombre     = data['nombre']      as String? ?? 'Sin nombre';
              final precio     = data['precio']      as num?    ?? 0;
              final imagenUrl  = data['imagen']      as String? ?? '';

              return GestureDetector(
                onTap: () {
                  // aquí podrías navegar al detalle del plato
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: imagenUrl.isNotEmpty
                                ? Image.network(imagenUrl, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade300),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('\$${precio.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
