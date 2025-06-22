// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyExpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 14),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color buttonGoogle     = Color(0xFFDB4437);
  static const Color buttonFacebook   = Color(0xFF3b5998);
  static const Color buttonOther      = Color(0xFF9E9E9E);
  static const Color textColor        = Color(0xFF333333);
  static const Color linkColor        = Color(0xFF6200EE);

  bool _loading = false;

  Future<void> signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // cancelado

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user     = userCred.user!;

      // Guardamos en Firestore
      final userDoc = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      await userDoc.set({
        'email'      : user.email,
        'displayName': user.displayName,
        'photoURL'   : user.photoURL,
        'lastLogin'  : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ¡Navega a InfoPage!
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InfoPage()),
      );
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Aquí el helper bien definido:
  Widget _buildButton(
    String text,
    IconData icon,
    Color backgroundColor, {
    required VoidCallback onPressed, // parámetro nombrado
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 5,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo / header…
              SizedBox(
                height: 273,
                width: double.infinity,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 30),
              Text(
                'Elige cómo quieres ingresar',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // GOOGLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildButton(
                  'Continuar con Google',
                  Icons.login,
                  buttonGoogle,
                  onPressed: _loading ? () {} : signInWithGoogle,
                ),
              ),
              const SizedBox(height: 20),

              // FACEBOOK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildButton(
                  'Continuar con Facebook',
                  Icons.facebook,
                  buttonFacebook,
                  onPressed: () {
                    // tu lógica de Facebook
                  },
                ),
              ),
              const SizedBox(height: 20),

              // OTRO MÉTODO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildButton(
                  'Otro método',
                  Icons.person_add,
                  buttonOther,
                  onPressed: () {
                    // tu lógica de otro método
                  },
                ),
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Al elegir ingresar con Google, Facebook, e-mail o celular, '
                  'estás aceptando los términos y condiciones de uso y políticas '
                  'de privacidad de EasyExpress.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Ya tengo una cuenta?",
                      style: TextStyle(color: textColor, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      // navegar a login tradicional
                    },
                    child: const Text("Entrar",
                        style: TextStyle(color: linkColor, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
