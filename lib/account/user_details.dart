// lib/account/user_details.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({Key? key}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late String uid;
  Map<String, dynamic> data = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    data = doc.data() ?? {};
    setState(() => loading = false);
  }

  Future<void> _editField(String field, String label) async {
    final controller = TextEditingController(text: data[field] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != data[field]) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .set({field: result}, SetOptions(merge: true));
      data[field] = result;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photoUrl = data['photoURL'] as String? ?? '';
    final name     = data['displayName'] as String? ?? '';
    final email    = data['email']       as String? ?? '';
    final phone    = data['phone']       as String? ?? '';
    final address  = data['address']     as String? ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // —— Header azul con avatar ——
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 160, width: double.infinity, color: Colors.blueAccent),
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 72,
                  child: const Text(
                    'Detalles del Usuario',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: MediaQuery.of(context).size.width / 2 - 50,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // —— Lista de campos —— 
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildTile('Nombres', name, editable: true, onEdit: () => _editField('displayName', 'Nombres')),
                _buildTile('Correo', email, editable: false),
                _buildTile('Teléfono', phone, editable: true, onEdit: () => _editField('phone', 'Teléfono')),
                _buildTile('Dirección', address, editable: true, onEdit: () => _editField('address', 'Dirección')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String label, String value,
      {required bool editable, VoidCallback? onEdit}) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(value.isNotEmpty ? value : '—'),
          trailing: editable
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: onEdit,
                )
              : null,
        ),
        const Divider(),
      ],
    );
  }
}
