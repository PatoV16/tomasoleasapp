import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tomasoleasapp/Screens/teacher/teacher.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Iniciar Sesión'),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido, Profesor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              CupertinoTextField(
                controller: emailController,
                placeholder: 'Email',
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Contraseña',
                obscureText: true,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              SizedBox(height: 32),
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                child: Text('Iniciar Sesión'),
                onPressed: () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    // Redirigir al dashboard del profesor después de iniciar sesión
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                          builder: (context) => TeacherDashboard()),
                    );
                  } catch (e) {
                    // Manejo de errores
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text('Error'),
                        content: Text(e.toString()),
                        actions: [
                          CupertinoDialogAction(
                            child: Text('Aceptar'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
