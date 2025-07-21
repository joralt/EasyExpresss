import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveComment() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe un comentario')),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo'; // Obtener el ID de usuario (o "anonimo" si no está autenticado)
      final comment = _controller.text;

      // Guardar en la colección SUPPORT_MESSAGES de Firestore
      await FirebaseFirestore.instance.collection('SUPPORT_MESSAGES').add({
        'userId': userId,
        'message': comment,
        'timestamp': FieldValue.serverTimestamp(), // Marca de tiempo
      });

      // Limpiar el campo de texto después de enviar
      _controller.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario enviado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hubo un error al enviar el comentario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envíanos tu consulta o problema:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveComment, // Enviar comentario
                child: const Text('Enviar'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Preguntas Frecuentes:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _faq('¿Cómo actualizo mi contraseña?',
                'Ve a la sección "Configuraciones" y selecciona "Cambiar Contraseña".'),
            const Divider(),
            _faq('¿Cómo elimino mi cuenta?',
                'En "Configuraciones", selecciona "Eliminar Cuenta". Sigue los pasos indicados.'),
            const Divider(),
            _faq('¿Cómo reporto un problema?',
                'Usa el formulario de esta página para enviarnos tu problema o consulta.'),
          ],
        ),
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
                text: '$q\n',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: a),
          ],
        ),
      ),
    );
  }
}
