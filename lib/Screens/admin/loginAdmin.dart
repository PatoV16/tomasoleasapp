import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tomasoleasapp/Screens/admin/admin.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _signInAdmin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Por favor, ingresa email y contraseña.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Autenticación de usuario con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      final User? user = userCredential.user;

      if (user != null) {
        // Verificar el rol en Firestore
        final doc = await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists && doc['role'] == 'admin') {
          _showMessage('Inicio de sesión exitoso.');
          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>AdminDashboard(),
                              maintainState: false
                            ),
                            
                          );
        } else {
          _showMessage('No tienes permisos de administrador.');
          await FirebaseAuth.instance.signOut(); // Cerrar sesión si no es admin
        }
      } else {
        _showMessage('Error en la autenticación.');
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Mensaje'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Login de Administrador'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                padding: EdgeInsets.all(16),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Contraseña',
                obscureText: true,
                padding: EdgeInsets.all(16),
              ),
              SizedBox(height: 32),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                child: isLoading
                    ? CupertinoActivityIndicator()
                    : Text('Iniciar Sesión'),
                onPressed: isLoading ? null : _signInAdmin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
