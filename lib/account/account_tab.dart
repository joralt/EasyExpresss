// lib/account/account_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'delete_account.dart';
import 'help_support.dart';
import 'notifications.dart';
import 'addresses.dart';
import 'user_details.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({Key? key}) : super(key: key);

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No hay usuario autenticado');
    }
    _uid = user.uid;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDoc() {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_uid)
        .get();
  }

  void _navigate(Widget page) {
    // 1️⃣ Oculta el teclado si estaba abierto
    FocusScope.of(context).unfocus();
    // 2️⃣ Navega
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _fetchUserDoc(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Error cargando datos')),
          );
        }

        final data        = snap.data!.data()!;
        final displayName = data['displayName'] as String? ?? 'Usuario';
        final email       = data['email']       as String? ?? '';
        final photoURL    = data['photoURL']    as String? ?? '';
        final geo         = data['location']    as GeoPoint?;
        final address     = geo != null
            ? '${geo.latitude.toStringAsFixed(5)}, ${geo.longitude.toStringAsFixed(5)}'
            : 'Dirección no disponible';

        // Envolver todo en GestureDetector para desenfocar al tocar fuera
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // —— Encabezado —— 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 48, bottom: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7E6), // amarillo suave
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: photoURL.isNotEmpty
                            ? NetworkImage(photoURL)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(address, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // —— Opciones —— 
                Expanded(
                  child: ListView(
                    children: [
                      _buildOption(
                        icon: Icons.person_outline,
                        label: 'Mis datos personales',
                        onTap: () => _navigate(const UserDetailsScreen()),
                      ),
                      _buildOption(
                        icon: Icons.location_on_outlined,
                        label: 'Mis direcciones',
                        onTap: () => _navigate(const AddressesScreen()),
                      ),
                      _buildOption(
                        icon: Icons.notifications_none,
                        label: 'Notificaciones',
                        onTap: () => _navigate(const NotificationsScreen()),
                      ),
                      _buildOption(
                        icon: Icons.delete_outline,
                        label: 'Eliminar Cuenta',
                        onTap: () => _navigate(const DeleteAccountScreen()),
                      ),
                      _buildOption(
                        icon: Icons.help_outline,
                        label: 'Ayuda y Soporte',
                        onTap: () => _navigate(const HelpSupportScreen()),
                      ),
                      const Divider(height: 32),
                      _buildOption(
                        icon: Icons.logout,
                        label: 'Cerrar Sesión',
                        iconColor: Colors.red,
                        labelColor: Colors.red,
                        onTap: () async {
                          FocusScope.of(context).unfocus();
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    Color iconColor = Colors.black87,
    Color labelColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: labelColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
