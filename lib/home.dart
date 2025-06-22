// home.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;  // ① campo

  const HomeScreen({
    Key? key,
    required this.userData,             // ② constructor
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildPlaceholderTab('Favoritos'),
            _buildPlaceholderTab('Pedidos'),
            _buildPlaceholderTab('Mi Cuenta'),
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
    final name = widget.userData['Nombres'] ?? 'Usuario';
    final address = widget.userData['Direccion'] ?? 'Dirección no disponible';
    final photoUrl = widget.userData['Foto'] as String?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // **Header** con datos reales
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
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
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildPromotionCarousel(),
          const SizedBox(height: 24),
          _buildSectionTitle('Categorías'),
          _buildCategories(),
          const SizedBox(height: 24),
          _buildSectionTitle('Recomendado para ti'),
          _buildRecommendations(),
          const SizedBox(height: 24),
          _buildSectionTitle('Te puede interesar'),
          _buildRecommendations(),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    final cats = ['Restaurantes', 'Rápida', 'Picanterías', 'Tiendas'];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) => Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0), shape: BoxShape.circle),
              child: Center(child: Text(cats[i][0])),
            ),
            const SizedBox(height: 8),
            Text(cats[i]),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 200,
            child: Column(
              children: const [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16))),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Producto',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String label) =>
      Center(child: Text(label, style: const TextStyle(fontSize: 24)));
}
