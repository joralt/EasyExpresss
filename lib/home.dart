import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          FavoritosScreen(onOrderConfirmed: () => setState(() => _currentIndex = 2)), 
          PedidosScreen(),
          AccountTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildPromotionCarousel(),
              const SizedBox(height: 24),
              _buildSectionTitle('Categorías'),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverCategoryDelegate(
            child: Container(
              color: const Color(0xFFF8F9FA),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildCategories(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildSectionTitle('Locales cerca de ti'),
              const SizedBox(height: 12),
              _buildLocalesSlider(),
              const SizedBox(height: 32),
              _buildSectionTitle('Recomendado para ti'),
              const SizedBox(height: 12),
              _buildPlatosRecomendados(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    final name = widget.userData['Nombres'] as String? ?? 'Usuario';
    final photoUrl = widget.userData['Foto'] as String? ?? '';
    
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF228B22),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF228B22), Color(0xFF1B5E20)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
            ],
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage = (constraints.maxHeight - kToolbarHeight) / (140.0 - kToolbarHeight);
            return Row(
              children: [
                if (percentage < 0.2) ...[
                  const Text('EasyExpress', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
                ] else ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola, $name 👋', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text('¿Qué pedimos hoy?', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                  if (result == 'ver_pedidos') setState(() => _currentIndex = 2);
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Consumer<CartProvider>(
                builder: (_, cart, __) => cart.itemCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 18, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF228B22),
            unselectedItemColor: Colors.grey.shade400,
            elevation: 0,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explorar'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favoritos'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Mis Pedidos'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Cuenta'),
            ],
          ),
        ),
      ),
    );
  }

// Eliminamos _buildHomeTab ya que ahora usamos Slivers directamente en build

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.black87, size: 22),
      onPressed: onTap,
    ),
  );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar restaurantes o platos...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      );

  Widget _buildPromotionCarousel() => SizedBox(
        height: 180,
        child: PageView.builder(
          itemCount: 3,
          controller: PageController(viewportFraction: 0.9),
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=1000'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.darken),
              ),
            ),
            child: Stack(children: [
              Positioned(
                bottom: 20, left: 20,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF228B22), borderRadius: BorderRadius.circular(8)),
                    child: const Text('PROMO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  const Text('¡20% OFF en tu primer pedido!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Text('Ver todo', style: TextStyle(color: const Color(0xFF228B22), fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
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
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CategoriaScreen(categoria: cat['label']!)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(cat['icon']!, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 10),
                  Text(cat['label']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocalesSlider() {
    return SizedBox(
      height: 220,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('LOCALES').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No hay locales'));
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      height: 240,
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
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _PlatoCard(
                nombre: d['nombre'] ?? 'Sin nombre',
                precio: (d['precio'] ?? 0).toDouble(),
                imagenUrl: d['imagen'] ?? '',
                onTap: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(
                    docs[i].id,
                    d['nombre'] ?? 'Sin nombre',
                    (d['precio'] ?? 0).toDouble(),
                    d['imagen'] ?? '',
                  );
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${d['nombre']} añadido al carrito'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'VER',
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                          if (result == 'ver_pedidos') setState(() => _currentIndex = 2);
                        },
                      ),
                    ),
                  );
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
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: widget.imagenUrl.isNotEmpty
                      ? Image.network(widget.imagenUrl, width: double.infinity, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade100, child: const Icon(Icons.store, color: Colors.grey)),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: _toggleFavorito,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        isFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorito ? Colors.red : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.nombre,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(widget.categoria,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
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
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: widget.imagenUrl.isNotEmpty
                    ? Image.network(widget.imagenUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                    : Container(color: Colors.grey.shade100, child: const Icon(Icons.restaurant, color: Colors.grey)),
              ),
              Positioned(
                top: 10, right: 10,
                child: GestureDetector(
                  onTap: _toggleFavorito,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      isFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFavorito ? Colors.red : Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text('\$${widget.precio.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF228B22), fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nombre,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF228B22).withOpacity(0.1),
                      foregroundColor: const Color(0xFF228B22),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Añadir+', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 110.0;

  @override
  double get minExtent => 110.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
