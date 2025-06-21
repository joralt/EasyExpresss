// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dirección de entrega',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB00823),
        fontFamily: 'Roboto',
      ),
      home: const DeliveryAddressPage(),
    );
  }
}

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({Key? key}) : super(key: key);

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  final TextEditingController _floorCtrl = TextEditingController();
  final TextEditingController _secondaryCtrl = TextEditingController();
  final TextEditingController _refsCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  int _refsCount = 0;
  String _selectedTag = 'Casa';
  String _countryDial = '+593';
  bool get _canSave =>
      _refsCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _selectedTag.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _refsCtrl.addListener(() {
      setState(() {
        _refsCount = _refsCtrl.text.length.clamp(0, 100);
      });
    });
  }

  @override
  void dispose() {
    _floorCtrl.dispose();
    _secondaryCtrl.dispose();
    _refsCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    // Aquí envías los datos a tu backend o Firestore
    final data = {
      'floor': _floorCtrl.text.trim(),
      'secondary': _secondaryCtrl.text.trim(),
      'refs': _refsCtrl.text.trim(),
      'phone': '$_countryDial ${_phoneCtrl.text.trim()}',
      'tag': _selectedTag,
    };
    debugPrint('Guardando dirección: $data');
    // Después de guardar, cerrar o navegar:
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirección de entrega'),
        leading: BackButton(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Text(
              'Detalles de la dirección',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Dirección fija:
            const Text(
              'Dirección *',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Unnamed Road'),
            ),
            const SizedBox(height: 16),

            // Piso / Apartamento
            TextField(
              controller: _floorCtrl,
              decoration: InputDecoration(
                hintText: 'Piso / Apartamento',
                border: border,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Calle secundaria
            TextField(
              controller: _secondaryCtrl,
              decoration: InputDecoration(
                hintText: 'Calle secundaria',
                border: border,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Referencias
            const Text(
              'Indicaciones para la entrega',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refsCtrl,
              maxLength: 100,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Referencias / Indicaciones para la entrega*',
                border: border,
                filled: true,
                fillColor: Colors.white,
                counterText: '$_refsCount/100',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Datos de contacto
            const Text(
              'Datos de contacto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Selector país (estático ejemplo)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Text('🇪🇨'),
                      const SizedBox(width: 6),
                      Text(_countryDial,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Número
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Ej: 099 123 4567',
                      border: border,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Te contactaremos solo en caso de que sea necesario.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Etiquetas
            const Text(
              '¿Qué nombre le damos a esta dirección?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Casa', 'Trabajo', 'Otro'].map((tag) {
                final bool selected = _selectedTag == tag;
                return ChoiceChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedTag = tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Botones
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSave ? _onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text(
                  'Guardar dirección',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'En otro momento',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
