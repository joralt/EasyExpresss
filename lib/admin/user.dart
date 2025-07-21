// lib/admin/usuarios_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  CollectionReference get _usuariosCol =>
      FirebaseFirestore.instance.collection('usuarios');

  void _eliminarUsuario(BuildContext ctx, String uid) async {
    await _usuariosCol.doc(uid).delete();
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Usuario eliminado con éxito')),
    );
  }

  Future<void> _mostrarFormularioAlta(BuildContext context) async {
    final _formKey     = GlobalKey<FormState>();
    final nameCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final phoneCtrl    = TextEditingController();
    final cedulaCtrl   = TextEditingController();
    final passwordCtrl = TextEditingController();

    bool validarCedula(String cedula) {
      if (cedula.length != 10) return false;
      final digits = cedula.split('').map(int.tryParse).toList();
      if (digits.contains(null)) return false;
      final provincia = digits[0]! * 10 + digits[1]!;
      if (provincia < 1 || provincia > 24) return false;
      int sum = 0;
      for (var i = 0; i < 9; i++) {
        int v = digits[i]!;
        if (i % 2 == 0) {
          v *= 2;
          if (v > 9) v -= 9;
        }
        sum += v;
      }
      final check = (10 - (sum % 10)) % 10;
      return check == digits[9];
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Wrap(children: [
          Text(
            'Agregar Repartidor',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(children: [
              // Nombre
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Email inválido',
              ),
              const SizedBox(height: 12),

              // Teléfono
              TextFormField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Teléfono (09XXXXXXXX)'),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.length != 10) {
                    return 'Debe tener 10 dígitos';
                  }
                  if (!v.startsWith('09')) {
                    return 'Debe comenzar con 09';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Cédula
              TextFormField(
                controller: cedulaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Cédula (10 dígitos)'),
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.length != 10) {
                    return 'Debe tener 10 dígitos';
                  }
                  if (!validarCedula(v)) {
                    return 'Cédula inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Contraseña
              TextFormField(
                controller: passwordCtrl,
                decoration:
                    const InputDecoration(labelText: 'Contraseña (mín. 6)'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón Agregar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Agregar'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await _usuariosCol.add({
                      'displayName': nameCtrl.text.trim(),
                      'email'      : emailCtrl.text.trim(),
                      'phone'      : phoneCtrl.text.trim(),
                      'cedula'     : cedulaCtrl.text.trim(),
                      'password'   : passwordCtrl.text,
                      'role'       : 'repartidor',
                      'createdAt'  : FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Repartidor agregado con éxito')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              
        ),
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _usuariosCol.snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        data['photoURL'] != null && data['photoURL'] != ''
                            ? NetworkImage(data['photoURL'])
                            : const AssetImage('assets/usuario.png')
                                as ImageProvider,
                  ),
                  title: Text(
                    data['displayName'] ??
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
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
                      PopupMenuItem(
                          value: 'modificar', child: Text('Modificar')),
                      PopupMenuItem(
                          value: 'eliminar', child: Text('Eliminar')),
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
        onPressed: () => _mostrarFormularioAlta(context),
      ),
    );
  }
}

// -----------------------------------------------------------
// La pantalla de ModificarUsuarioScreen la dejas igual a tu código
// -----------------------------------------------------------
// (no la repito aquí para no saturar, queda idéntica a la que ya tienes)


// -----------------------------------------------------------
// Pantalla de Modificación (igual a la tuya)
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
  State<ModificarUsuarioScreen> createState() =>
      _ModificarUsuarioScreenState();
}

class _ModificarUsuarioScreenState extends State<ModificarUsuarioScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('usuarios');

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _nameCtrl =
        TextEditingController(text: d['displayName'] ?? '');
    _emailCtrl = TextEditingController(text: d['email'] ?? '');
    _phoneCtrl = TextEditingController(text: d['phone'] ?? '');
    _addressCtrl = TextEditingController(text: d['address'] ?? '');
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
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
    };
    try {
      await _col.doc(widget.userId).update(upd);
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
          child: Column(children: [
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nombre completo'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email inválido',
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Guardar cambios',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
