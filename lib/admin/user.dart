// lib/admin/usuarios_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['photoURL'] != null && data['photoURL'] != ''
                        ? NetworkImage(data['photoURL'])
                        : const AssetImage('assets/usuario.png') as ImageProvider,
                  ),
                  title: Text(
                    data['displayName'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['email'] ?? 'Sin email'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'modificar') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModificarUsuarioScreen(
                              userId: docs[i].id,
                              userData: data,
                            ),
                          ),
                        );
                      } else if (val == 'eliminar') {
                        _eliminarUsuario(context, docs[i].id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'modificar', child: Text('Modificar')),
                      PopupMenuItem(value: 'eliminar',   child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarUsuarioScreen()),
          );
        },
      ),
    );
  }

  void _eliminarUsuario(BuildContext ctx, String uid) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).delete();
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Usuario eliminado con éxito')),
    );
  }
}

// -----------------------------------------------------------
// Pantalla para agregar (vacía para que compile)
// -----------------------------------------------------------
class AgregarUsuarioScreen extends StatelessWidget {
  const AgregarUsuarioScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Usuario')),
      body: const Center(child: Text('Formulario de alta aquí')),
    );
  }
}

// -----------------------------------------------------------
// Pantalla de Modificación
// -----------------------------------------------------------
class ModificarUsuarioScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ModificarUsuarioScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ModificarUsuarioScreen> createState() => _ModificarUsuarioScreenState();
}

class _ModificarUsuarioScreenState extends State<ModificarUsuarioScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _nameCtrl    = TextEditingController(text: d['displayName'] ?? '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}');
    _emailCtrl   = TextEditingController(text: d['email']       ?? '');
    _phoneCtrl   = TextEditingController(text: d['phone']       ?? '');
    _addressCtrl = TextEditingController(text: d['address']     ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final upd = {
      'displayName': _nameCtrl.text.trim(),
      'email'      : _emailCtrl.text.trim(),
      'phone'      : _phoneCtrl.text.trim(),
      'address'    : _addressCtrl.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .update(upd);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario modificado con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al modificar: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modificar Usuario'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.contains('@') ? null : 'Email inválido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _guardarCambios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
