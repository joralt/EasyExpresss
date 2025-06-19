import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
//ssisjishi

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const Color primary = Color(0xFFB00823);
  static const Color secondary = Color(0xFF3b5998);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color buttonBackground = Color(0xFFDB4437);
  static const Color buttonFacebook = Color(0xFF3b5998);
  static const Color buttonOther = Color(0xFF9E9E9E);
  static const Color textColor = Color(0xFF333333);
  static const Color linkColor = Color(0xFF6200EE);

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset('assets/logo.png', width: 320),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Elige cómo quieres ingresar',
                    style: Theme.of(context).textTheme.titleLarge!,
                  ),
                  const SizedBox(height: 40),
                  _buildButton(
                    context,
                    'Continuar con Google',
                    Icons.login,
                    buttonBackground,
                    _signInWithGoogle,
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    context,
                    'Continuar con Facebook',
                    Icons.facebook,
                    buttonFacebook,
                    (context) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidad de Facebook no implementada',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    context,
                    'Otro método',
                    Icons.person_add,
                    buttonOther,
                    (context) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidad de otro método no implementada',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Al elegir ingresar con Google, Facebook, e-mail o celular, estás aceptando los términos y condiciones de uso y políticas de privacidad de EasyExpress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "¿Ya tienes una cuenta?",
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          // Puedes añadir navegación a otro login aquí
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(color: linkColor, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    Color backgroundColor,
    Function(BuildContext) onPressed,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton.icon(
        onPressed: () => onPressed(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        icon: Icon(icon, size: 30, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenido, ${user?.displayName ?? 'Usuario'}',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
