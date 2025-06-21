// info.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'map_ubi.dart';


class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _birthDateCtrl;
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
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '';
    final parts = displayName.split(' ');
    _firstNameCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _lastNameCtrl = TextEditingController(text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _birthDateCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _birthDateCtrl.dispose();
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final data = {
      'firstName'       : _firstNameCtrl.text.trim(),
      'lastName'        : _lastNameCtrl.text.trim(),
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
      // Navegar a map_info.dart
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapInfoPage()),
      );
    } catch (e) {
      debugPrint('Error guardando perfil: \$e');
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ahora no', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      // Uso de ListView para evitar conflictos
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Completa tus datos para terminar de crear tu cuenta.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Nombre
          const Text('¿Cómo te llamas?'),
          const SizedBox(height: 8),
          TextField(
            controller: _firstNameCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre(s)*',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameCtrl,
            decoration: InputDecoration(
              labelText: 'Apellido(s)*',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Fecha de nacimiento
          const Text('¿Cuándo naciste?'),
          const SizedBox(height: 8),
          TextField(
            controller: _birthDateCtrl,
            readOnly: true,
            onTap: _selectDate,
            decoration: InputDecoration(
              hintText: 'DD/MM/AAAA',
              suffixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          const SizedBox(height: 40),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Guardar datos', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
