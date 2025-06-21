// home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int next = (_pageController.page?.toInt() ?? 0) + 1;
        if (next >= 3) next = 0;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomePage(),
            FavoritesScreen(correo: widget.userData['Correo']),
            OrdersScreen(userId: widget.userData['Correo']),
            AccountScreen(userData: widget.userData),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF228B22),
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          _navItem('assets/h.png', 'Inicio', 0),
          _navItem('assets/f.png', 'Favoritos', 1),
          _navItem('assets/p.png', 'Pedidos', 2),
          _navItem('assets/c.png', 'Cuenta', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(String asset, String label, int idx) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        asset,
        width: 24,
        height: 24,
        color: _currentIndex == idx ? const Color(0xFF228B22) : Colors.grey,
      ),
      label: label,
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildPromotionCarousel(),
          const SizedBox(height: 20),
          _buildSectionTitle('Categorías'),
          _buildCategories(),
          const SizedBox(height: 20),
          _buildSectionTitle('Recomendado para ti'),
          // Placeholder for recommended
          const SizedBox(height: 20),
          _buildSectionTitle('Te puede interesar'),
          // Placeholder for interests
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = widget.userData['Nombres'] ?? 'Usuario';
    final photo = widget.userData['Foto'] as String?;
    final address = widget.userData['location'] != null
        ? '${(widget.userData['location'] as GeoPoint).latitude.toStringAsFixed(4)}, ${(widget.userData['location'] as GeoPoint).longitude.toStringAsFixed(4)}'
        : 'Dirección no disponible';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: photo != null && photo.isNotEmpty
                    ? NetworkImage(photo)
                    : const AssetImage('assets/user.png') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(address, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, size: 30),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CartScreen(userId: widget.userData['Correo']),
                  ));
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 30),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userData: widget.userData),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onChanged: (v) {},
        decoration: InputDecoration(
          hintText: 'Local, comida o producto favorito',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCarousel() {
    // Placeholder container
    return SizedBox(
      height: 150,
      child: PageView(
        controller: _pageController,
        children: List.generate(3, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[300],
          ),
          child: Center(child: Text('Promo ${i+1}')), 
        )),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCategories() {
    // Placeholder row
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: List.generate(6, (i) => Container(
          width: 80,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: Center(child: Text('Cat ${i+1}')),
        )),
      ),
    );
  }
}

















class NotificationsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const NotificationsScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Center(child: Text('Notificaciones para ${userData['Nombres']}')),
    );
  }
}



class CartScreen extends StatelessWidget {
  final String userId;
  const CartScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: Center(child: Text('Carrito de $userId')),
    );
  }
}


class AccountScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const AccountScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Cuenta')),
      body: Center(child: Text('Cuenta de ${userData['Nombres']}')),
    );
  }
}


class OrdersScreen extends StatelessWidget {
  final String userId;
  const OrdersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: Center(child: Text('Aquí irán los pedidos de $userId')),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final String correo;
  const FavoritesScreen({super.key, required this.correo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Center(child: Text('Aquí irán los favoritos de $correo')),
    );
  }
}
