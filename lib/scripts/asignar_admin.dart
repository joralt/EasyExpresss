// scripts/asignar_admin.dart

import 'package:flutter/widgets.dart';                     // ← para WidgetsFlutterBinding
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';                         // ajusta la ruta si está en lib/

Future<void> main() async {
  // Inicializa Flutter/Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ejecuta la asignación
  await asignarRolAdmin();
  print('✅ Listo: rol de admin asignado');
  // opcionalmente: exit(0);
}

Future<void> asignarRolAdmin() async {
  // 1) Credenciales de tu admin preexistente en Auth
  const email    = 'admin@tudominio.com';
  const password = 'SuPasswordSeguro';

  // 2) Autentícate para obtener el UID
  final cred = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
  final uid = cred.user!.uid;

  // 3) Graba el campo `role: 'admin'` en Firestore
  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .set({
        'role'       : 'admin',
        'displayName': 'Administrador',
        'email'      : email,
        'createdAt'  : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  print('Rol admin asignado al usuario $uid');
}
