import 'package:flutter/material.dart';
import 'user.dart';
import 'local.dart';
import 'addadmin.dart';
import 'suport.dart';

class AdminDashboard extends StatefulWidget {
  final String adminName;

  const AdminDashboard({Key? key, required this.adminName}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _screens = [
    const UsuariosScreen(),
    LocalesScreen(),
    const RepartidorScreen(),
    const SupportMessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Administrador',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isDrawerOpen = !_isDrawerOpen; // Toggle the Drawer visibility
            });
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Barra lateral con botones
          _isDrawerOpen
              ? NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.people),
                      label: Text('Usuarios'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.store),
                      label: Text('Locales'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Repartidores'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      label: Text('Soporte Técnico'),
                    ),
                  ],
                )
              : SizedBox.shrink(), // Ocultar la barra lateral si _isDrawerOpen es false

          // Sección de contenido a la derecha
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }
}
