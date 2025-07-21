import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CuentaScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userPhone;

  const CuentaScreen({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        backgroundColor: const Color(0xFF6F35A5),
        centerTitle: true,
                automaticallyImplyLeading: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostrar foto de perfil
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://www.example.com/profile_image.png', // Imagen de perfil, puedes cambiarla según lo que necesites
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nombre: $userName',
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              'Correo electrónico: $userEmail',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Teléfono: $userPhone',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
