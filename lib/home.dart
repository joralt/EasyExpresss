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
  const HomeScreen({Key? key, required this.userData}) : super(key: key);

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
            FavoritosScreen(), // sin const para refrescar
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
          BottomNavigationBarItem(icon: Icon(Icons.home),           label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite),       label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag),  label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.person),         label: 'Cuenta'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final name     = widget.userData['Nombres']   as String? ?? 'Usuario';
    final address  = widget.userData['Direccion'] as String? ?? '';
    final photoUrl = widget.userData['Foto']      as String? ?? '';

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ─── HEADER ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hola, $name',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(color: Colors.black54)),
              ]),
            ]),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildPromotionCarousel(),
        const SizedBox(height: 24),
        _buildSectionTitle('Categorías'),
        _buildCategories(),
        const SizedBox(height: 24),
        _buildSectionTitle('Locales cerca de ti'),
        const SizedBox(height: 12),
        _buildLocalesSlider(),
        const SizedBox(height: 24),
        _buildSectionTitle('Recomendado para ti'),
        const SizedBox(height: 12),
        _buildPlatosRecomendados(),
        const SizedBox(height: 24),
      ]),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold))),
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
      {'icon': 'assets/rapida.png', 'label': 'Rápida'},
      {'icon': 'assets/piocanteria.png', 'label': 'Picanterías'},
      {'icon': 'assets/tienda.png', 'label': 'Tiendas'},
      {'icon': 'assets/farmacia.png', 'label': 'Farmacias'},
      {'icon': 'assets/heladeria.png', 'label': 'Heladerias'},
      {'icon': 'assets/licor.png', 'label': 'Licorerías'},
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CategoriaScreen(categoria: cat['label']!)),
                ),
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
          if (docs.isEmpty) return const Center(child: Text('No hay locales'));
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _LocaleCard(
                localId: docs[i].id,
                nombre: d['Nombre'] ?? 'Sin nombre',
                categoria: d['Categoria'] ?? '',
                imagenUrl: d['Imagen'] ?? '',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LocalDetailScreen(
                          localId: docs[i].id,
                          localName: d['Nombre'] ?? ''))),
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
          if (docs.isEmpty) return const Center(child: Text('No hay platos'));
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _PlatoCard(
                nombre: d['nombre'] ?? 'Sin nombre',
                precio: (d['precio'] ?? 0).toDouble(),
                imagenUrl: d['imagen'] ?? '',
                onTap: () {
                  // futuro: agregar al carrito
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LocaleCard extends StatefulWidget {
  final String localId, nombre, categoria, imagenUrl;
  final VoidCallback onTap;
  const _LocaleCard({
    required this.localId,
    required this.nombre,
    required this.categoria,
    required this.imagenUrl,
    required this.onTap,
  });
  @override
  __LocaleCardState createState() => __LocaleCardState();
}

class __LocaleCardState extends State<_LocaleCard> {
  late bool isFavorito;

  @override
  void initState() {
    super.initState();
    isFavorito = FavoritosScreen.localesFavoritos.any(
      (loc) => loc['id'] == widget.localId,
    );
  }

  void _toggleFavorito() {
    setState(() => isFavorito = !isFavorito);
    if (isFavorito) {
      FavoritosScreen.localesFavoritos.add({
        'id': widget.localId,
        'nombre': widget.nombre,
        'imagenUrl': widget.imagenUrl,
        'categoria': widget.categoria,
      });
    } else {
      FavoritosScreen.localesFavoritos
          .removeWhere((loc) => loc['id'] == widget.localId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: 200,
          child: Column(
            children: [
              Expanded(
                child: Stack(children: [
                  Positioned.fill(
                    child: widget.imagenUrl.isNotEmpty
                        ? Image.network(widget.imagenUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade300),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorito,
                      child: Icon(
                        isFavorito
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorito ? Colors.red : Colors.white,
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.categoria,
                        style:
                            const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatoCard extends StatefulWidget {
  final String nombre, imagenUrl;
  final double precio;
  final VoidCallback onTap;
  const _PlatoCard({
    required this.nombre,
    required this.precio,
    required this.imagenUrl,
    required this.onTap,
  });
  @override
  __PlatoCardState createState() => __PlatoCardState();
}

class __PlatoCardState extends State<_PlatoCard> {
  late bool isFavorito;

  @override
  void initState() {
    super.initState();
    isFavorito = FavoritosScreen.productosFavoritos.any(
      (p) => p['nombre'] == widget.nombre,
    );
  }

  void _toggleFavorito() {
    setState(() => isFavorito = !isFavorito);
    if (isFavorito) {
      FavoritosScreen.productosFavoritos.add({
        'nombre': widget.nombre,
        'imagenUrl': widget.imagenUrl,
        'precio': widget.precio.toStringAsFixed(2),
      });
    } else {
      FavoritosScreen.productosFavoritos
          .removeWhere((p) => p['nombre'] == widget.nombre);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                Positioned.fill(
                  child: widget.imagenUrl.isNotEmpty
                      ? Image.network(widget.imagenUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorito,
                    child: Icon(
                      isFavorito
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorito ? Colors.red : Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onTap,
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
              ]),
            ),
            Padding(
	            padding: const EdgeInsets.all(8),
	            child: Column(
	              crossAxisAlignment: CrossAxisAlignment.start,
	              children: [
	                Text(widget.nombre,
	                    style: const TextStyle(fontWeight: FontWeight.bold)),
	                const SizedBox(height: 4),
	                Text('\$${widget.precio.toStringAsFixed(2)}',
	                    style: const TextStyle(color: Colors.black54)),
	              ],
	            ),
	          ),
          ],
        ),
      ),
    );
  }
}
