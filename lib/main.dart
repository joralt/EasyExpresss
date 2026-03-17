import 'admin/admin_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyExpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF228B22),
          primary: const Color(0xFF228B22),
          secondary: const Color(0xFF1B5E20),
          surface: Colors.white,
          background: const Color(0xFFF8F9FA),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF757575)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
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
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color buttonGoogle     = Color(0xFFFFFFFF);
  static const Color buttonFacebook   = Color(0xFF1877F2);
  static const Color buttonOther      = Color(0xFF1A1A1A);
  static const Color textColor        = Color(0xFF1A1A1A);
  static const Color linkColor        = Color(0xFF228B22);

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
    Widget icon,
    Color backgroundColor,
    Color foregroundColor, {
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: backgroundColor == Colors.white 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: backgroundColor == Colors.white 
              ? BorderSide(color: Colors.grey.shade200) 
              : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo con mejor presentacion
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'EasyExpress',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu ciudad a un toque de distancia',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),

              // GOOGLE
              _buildButton(
                'Continuar con Google',
                Image.network('https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png', height: 24),
                buttonGoogle,
                textColor,
                onPressed: _loading ? () {} : signInWithGoogle,
              ),
              const SizedBox(height: 16),

              // FACEBOOK
              _buildButton(
                'Continuar con Facebook',
                const Icon(Icons.facebook, size: 24),
                buttonFacebook,
                Colors.white,
                onPressed: () {},
              ),
              const SizedBox(height: 16),

              // OTRO MÉTODO
              _buildButton(
                'Otro método',
                const Icon(Icons.mail_outline, size: 24),
                buttonOther,
                Colors.white,
                onPressed: () {},
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Al elegir ingresar con Google, Facebook, e-mail o celular, '
                  'estás aceptando los términos y condiciones de uso y políticas '
                  'de privacidad de EasyExpress.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Eres administrador?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                      );
                    },
                    child: const Text("Entrar aquí",
                      style: TextStyle(color: linkColor, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
