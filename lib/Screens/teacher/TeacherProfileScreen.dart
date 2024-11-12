import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherProfileScreen extends StatefulWidget {
  @override
  _TeacherProfileScreenState createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser; // Obtener el usuario actual
  String teacherCedula = 'Cargando...';
  String teacherEmail = 'Cargando...';
  String teacherName = 'Cargando...';
  String teacherRole = 'Cargando...';
  String teacherTitulo = 'Cargando...';
  String teacherPhotoUrl = ''; // URL de la foto del profesor (opcional)

  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _tituloController = TextEditingController();
  final _passwordController = TextEditingController(); // Controlador para la contraseña

  @override
  void initState() {
    super.initState();
    _fetchTeacherProfile();
  }

  Future<void> _fetchTeacherProfile() async {
    if (user != null) {
      final uid = user!.uid;
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('uid', isEqualTo: uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = querySnapshot.docs.first;
          setState(() {
            teacherCedula = doc['cedula'] ?? 'No disponible';
            teacherEmail = doc['email'] ?? 'No disponible';
            teacherName = doc['nombre'] ?? 'No disponible';
            teacherRole = doc['role'] ?? 'No disponible';
            teacherTitulo = doc['titulo'] ?? 'No disponible';

            // Inicializa los controladores con los valores actuales
            _cedulaController.text = teacherCedula;
            _emailController.text = teacherEmail;
            _nameController.text = teacherName;
            _roleController.text = teacherRole;
            _tituloController.text = teacherTitulo;
          });
        } else {
          print("No se encontró el perfil del profesor.");
        }
      } catch (e) {
        print("Error al obtener el perfil del profesor: $e");
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user != null) {
      final uid = user!.uid;
      try {
        await FirebaseFirestore.instance.collection('profesores').doc(uid).update({
          'cedula': _cedulaController.text,
          'email': _emailController.text,
          'nombre': _nameController.text,
          'role': _roleController.text,
          'titulo': _tituloController.text,
        });

        // Cambiar el email en FirebaseAuth si es necesario
        await user?.updateEmail(_emailController.text);

        // Cambiar la contraseña solo si se proporciona
        if (_passwordController.text.isNotEmpty) {
          await user?.updatePassword(_passwordController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil actualizado con éxito.')),
        );
      } catch (e) {
        print("Error al actualizar el perfil: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Perfil del Profesor'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: teacherPhotoUrl.isNotEmpty
                      ? NetworkImage(teacherPhotoUrl)
                      : null,
                  child: teacherPhotoUrl.isEmpty
                      ? Icon(CupertinoIcons.person, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              // Campos de texto para mostrar información
              CupertinoTextField(
                placeholder: 'Cédula',
                controller: _cedulaController,
                enabled: false,
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'Nombre',
                controller: _nameController,
                enabled: false, // Campo bloqueado
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'Correo Electrónico',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Campo bloqueado
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'Rol',
                controller: _roleController,
                enabled: false, // Campo bloqueado
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'Título',
                controller: _tituloController,
                enabled: false, // Campo bloqueado
              ),
              SizedBox(height: 16),
              // Campo para cambiar la contraseña
              CupertinoTextField(
                placeholder: 'Nueva Contraseña (opcional)',
                controller: _passwordController,
                obscureText: true, // Ocultar texto para la contraseña
              ),
              SizedBox(height: 24),
              // Botón para guardar cambios
              CupertinoButton(
                color: CupertinoColors.activeBlue,
                child: Text('Guardar Cambios'),
                onPressed: _updateProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
