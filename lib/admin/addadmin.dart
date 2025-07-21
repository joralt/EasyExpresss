// lib/admin/repartidor_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RepartidorScreen extends StatefulWidget {
  const RepartidorScreen({Key? key}) : super(key: key);

  @override
  _RepartidorScreenState createState() => _RepartidorScreenState();
}

class _RepartidorScreenState extends State<RepartidorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController cedulaCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  CollectionReference get _usuariosCol =>
      FirebaseFirestore.instance.collection('usuarios');

  // Stream to display only delivery drivers (role: 'repartidor')
  Stream<QuerySnapshot> get _repartidoresStream {
    return _usuariosCol.where('role', isEqualTo: 'repartidor').snapshots();
  }

  // Function to add a new delivery driver
  Future<void> _addRepartidor() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Add new delivery driver to Firestore
      await _usuariosCol.add({
        'displayName': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'cedula': cedulaCtrl.text.trim(),
        'role': 'repartidor', // Assign role as 'repartidor'
        'password': passwordCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repartidor agregado con éxito')),
      );
      Navigator.pop(context); // Close the form
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar repartidor: $e')),
      );
    }
  }

  // Function to show form to add a new repartidor
  Future<void> _showAddRepartidorForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Agregar Nuevo Repartidor',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : 'Requerido',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Email inválido',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cedulaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cédula',
                        prefixIcon: Icon(Icons.card_membership),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addRepartidor,
                      child: const Text('Agregar Repartidor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to modify an existing repartidor
  Future<void> _modifyRepartidor(String id, Map<String, dynamic> data) async {
    nameCtrl.text = data['displayName'] ?? '';
    emailCtrl.text = data['email'] ?? '';
    phoneCtrl.text = data['phone'] ?? '';
    cedulaCtrl.text = data['cedula'] ?? '';
    passwordCtrl.text = data['password'] ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Modificar Repartidor',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : 'Requerido',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Email inválido',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cedulaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cédula',
                        prefixIcon: Icon(Icons.card_membership),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        await _usuariosCol.doc(id).update({
                          'displayName': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'cedula': cedulaCtrl.text.trim(),
                          'password': passwordCtrl.text.trim(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Repartidor modificado con éxito')),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Modificar Repartidor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to delete a repartidor
  Future<void> _deleteRepartidor(String id) async {
    try {
      await _usuariosCol.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repartidor eliminado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar repartidor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repartidores'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Display the list of delivery drivers (repartidores)
            StreamBuilder<QuerySnapshot>(
              stream: _repartidoresStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['photoURL'] != null &&
                                  data['photoURL'] != ''
                              ? NetworkImage(data['photoURL'])
                              : const AssetImage('assets/usuario.png')
                                  as ImageProvider,
                        ),
                        title: Text(
                          data['displayName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['email']),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'modificar') {
                              _modifyRepartidor(docs[i].id, data);
                            } else if (val == 'eliminar') {
                              _deleteRepartidor(docs[i].id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'modificar', child: Text('Modificar')),
                            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRepartidorForm(context),
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
