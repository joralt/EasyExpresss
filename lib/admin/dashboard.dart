// lib/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'user.dart';
import 'local.dart';
import 'addadmin.dart';
import 'suport.dart';

class AdminDashboard extends StatelessWidget {
  final String adminName;

  const AdminDashboard({Key? key, required this.adminName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Saludo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
  '¡Hola, $adminName!',
  textAlign: TextAlign.center,
  style: Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(fontWeight: FontWeight.bold),
),

          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tus tareas administrativas de forma eficiente',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),

          // La grid ocupa el resto
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCard(
                  context,
                  label: 'Usuarios',
                  icon: Icons.people,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                    );
                  },
                ),
                _buildCard(
                  context,
                  label: 'Locales',
                  icon: Icons.store,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  LocalesScreen()),
                    );
                  },
                ),
                _buildCard(
                  context,
                  label: 'Administradores',
                  icon: Icons.person,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddAdminScreen()),
                    );
                  },
                ),
                _buildCard(
                  context,
                  label: 'Soporte técnico',
                  icon: Icons.support_agent_outlined,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SupportMessagesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[100],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Perfil',
          ),
        ],
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            // Si pulsas Perfil, aquí podrías navegar a tu ProfileScreen
            // Navigator.push(...);
          }
        },
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
