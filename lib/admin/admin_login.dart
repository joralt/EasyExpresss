// lib/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard.dart';      // tu AdminDashboard
import '../delivery/delivery.dart';  // tu RepartidorApp

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _userId    = '';
  String _password  = '';
  bool   _loading   = false;
  String? _errorMsg;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (_userId.contains('@')) {
        // ——— ADMINISTRADOR —————
        // login via FirebaseAuth
        final cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: _userId, password: _password);
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .get();
        final role = doc.data()?['role'] as String? ?? '';
        if (role != 'admin') throw Exception('No eres admin');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(
              adminName: doc.data()?['displayName'] ?? _userId,
            ),
          ),
        );

      } else {
        // ——— REPARTIDOR —————
        // busco en Firestore por cédula + password + role
        final qs = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('cedula', isEqualTo: _userId)
            .where('password', isEqualTo: _password)
            .where('role', isEqualTo: 'repartidor')
            .limit(1)
            .get();
        if (qs.docs.isEmpty) throw Exception('No eres repartidor');
        final data = qs.docs.first.data();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RepartidorApp(
              repartidorData: {
                'id'       : qs.docs.first.id,
                'nombre'   : data['displayName'],
                'telefono' : data['phone'],
                'cedula'   : data['cedula'],
                'direccion': data['address'],
              },
            ),
          ),
        );
      }

    } catch (e) {
      setState(() => _errorMsg = 'Credenciales inválidas');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const placeholderStyle = TextStyle(color: Colors.black38);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const SizedBox(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text(
                'EasyExpress',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ingresa con tu correo (admin) o tu cédula (repartidor) y contraseña',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Formulario
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Usuario (correo o cédula)
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Correo o cédula',
                          hintStyle: placeholderStyle,
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (!v.contains('@') && v.length != 10) {
                            return 'Cédula inválida';
                          }
                          return null;
                        },
                        onSaved: (v) => _userId = v!.trim(),
                      ),
                      const SizedBox(height: 16),
                      // Contraseña
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: placeholderStyle,
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                        validator: (v) => (v != null && v.length >= 6)
                            ? null
                            : 'Mínimo 6 caracteres',
                        onSaved: (v) => _password = v!,
                      ),
                      const SizedBox(height: 16),
                      if (_errorMsg != null)
                        Text(_errorMsg!,
                            style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
