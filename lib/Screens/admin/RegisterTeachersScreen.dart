import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterTeachersScreen extends StatefulWidget {
  @override
  _RegisterTeachersScreenState createState() => _RegisterTeachersScreenState();
}

class _RegisterTeachersScreenState extends State<RegisterTeachersScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _addTeacherToFirebase(BuildContext context) async {
    final String nombre = nombreController.text;
    final String cedula = cedulaController.text;
    final String titulo = tituloController.text;
    final String email = emailController.text;
    final String password = passwordController.text;

    if (nombre.isEmpty || cedula.isEmpty || titulo.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      // Crear el usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos del profesor en Firestore
      await FirebaseFirestore.instance.collection('profesores').doc(cedula).set({
        'nombre': nombre,
        'cedula': cedula,
        'titulo': titulo,
        'email': email,
        'role': 'profesor', // Asignamos el rol como profesor
        'uid': userCredential.user?.uid, // Guardamos el uid de Firebase Auth
      });

      // Limpiar los campos
      nombreController.clear();
      cedulaController.clear();
      tituloController.clear();
      emailController.clear();
      passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profesor registrado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el profesor: $e')),
      );
    }
  }

  Future<void> _deleteTeacher(String cedula) async {
    try {
      // Eliminar el profesor de Firestore
      await FirebaseFirestore.instance.collection('profesores').doc(cedula).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profesor eliminado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el profesor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Profesores')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro de Profesor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: cedulaController,
              placeholder: 'Cédula (ID)',
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: nombreController,
              placeholder: 'Nombre',
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: tituloController,
              placeholder: 'Título',
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: emailController,
              placeholder: 'Correo Electrónico',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: passwordController,
              placeholder: 'Contraseña',
              obscureText: true,
            ),
            SizedBox(height: 16),
            CupertinoButton.filled(
              child: Text('Registrar Profesor'),
              onPressed: () => _addTeacherToFirebase(context),
            ),
            SizedBox(height: 24),
            Text(
              'Lista de Profesores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('profesores').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No hay profesores registrados.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['nombre'] ?? ''),
                        subtitle: Text('${data['titulo'] ?? ''} - Cédula: ${data['cedula'] ?? ''}'),
                        trailing: IconButton(
                          icon: Icon(CupertinoIcons.delete, color: CupertinoColors.destructiveRed),
                          onPressed: () => _deleteTeacher(data['cedula']),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
