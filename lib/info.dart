// lib/info.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../map_ubi.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthDateCtrl;
  late TextEditingController _addressDescCtrl; 
  String _selectedGender = '';
  DateTime? _pickedDate;

  final List<String> _genders = [
    'Femenino',
    'Masculino',
    'No binario',
    'Prefiero no decirlo',
  ];

  @override
  void initState() {
    super.initState();
    final user        = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '';
    final parts       = displayName.split(' ');
    _firstNameCtrl    = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _lastNameCtrl     = TextEditingController(text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _phoneCtrl        = TextEditingController();
    _birthDateCtrl    = TextEditingController();
    _addressDescCtrl  = TextEditingController();   // <—¡inicialización!
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _addressDescCtrl.dispose();  // <—¡dispose también!
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initial = DateTime.now().subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid    = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final data = {
      'firstName'       : _firstNameCtrl.text.trim(),
      'lastName'        : _lastNameCtrl.text.trim(),
      'phone'           : _phoneCtrl.text.trim(),
      'addressDesc'     : _addressDescCtrl.text.trim(),
      'birthDate'       : _birthDateCtrl.text.trim(),
      'gender'          : _selectedGender,
      'profileCompleted': true,
    };
    try {
      await docRef.set(data, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados correctamente')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapInfoPage()),
      );
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar los datos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuéntanos más de ti'),
        actions: [
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Completa tus datos para terminar de crear tu cuenta.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _firstNameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre(s)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Apellidos
            TextFormField(
              controller: _lastNameCtrl,
              decoration: InputDecoration(
                labelText: 'Apellido(s)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Teléfono
            const Text('Numero de telefono (opcional)'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLength: 10,
              validator: (v) {
                final val = v?.trim() ?? '';
                if (!RegExp(r'^09\d{8}$').hasMatch(val)) {
                  return 'Debe comenzar con 09 y tener 10 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción de domicilio
            const Text('Referencia de domicilio (opcional)'),
            TextFormField(
              controller: _addressDescCtrl,
              decoration: InputDecoration(
                hintText: 'Es para que tus pedidos lleguen justo donde necesitas',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLength: 100,
              maxLines: 2,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
            ),
            const SizedBox(height: 9),

            // Fecha de nacimiento
            const Text('Fecha de nacimiento'),
            TextFormField(
              controller: _birthDateCtrl,
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(
                hintText: 'DD/MM/AAAA',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),

            // Género
            const Text('¿Con qué género te identificas?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _genders.map((g) {
                final selected = g == _selectedGender;
                return ChoiceChip(
                  label: Text(g),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedGender = g),
                );
              }).toList(),
            ),
            if (_selectedGender.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Requerido', style: TextStyle(color: Colors.red[700])),
              ),
            const SizedBox(height: 40),

            // Botón Continuar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedGender.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona un género')),
                    );
                    return;
                  }
                  _saveProfile();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Continuar', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
