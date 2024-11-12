import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student.dart';

class StudentLoginScreen extends StatefulWidget {
  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

 Future<void> _loginWithCedula() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final cedula = _cedulaController.text.trim();

  if (cedula.isEmpty) {
    setState(() {
      _errorMessage = 'Por favor, ingrese su número de cédula.';
      _isLoading = false;
    });
    return;
  }

  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('estudiantes')
        .doc(cedula)
        .get();

    if (docSnapshot.exists) {
      // Obtenemos el nombre y el curso_id del estudiante desde Firestore
      final nombre = docSnapshot.get('nombre');
      final cursoId = docSnapshot.get('curso_id');  // Suponiendo que 'curso_id' es un campo del estudiante

      // Navega al Dashboard y pasa el nombre, studentId y curso_id
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => AcademicDashboard(
            nombreEstudiante: nombre,
            studentId: cedula,
            cursoId: cursoId,  // Pasamos el curso_id
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Cédula no registrada.';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Ocurrió un error. Inténtelo de nuevo.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Ingreso Estudiante'),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: _cedulaController,
                placeholder: 'Ingrese su número de cédula',
                keyboardType: TextInputType.number,
                clearButtonMode: OverlayVisibilityMode.editing,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16),
              ],
              _isLoading
                  ? CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                      child: Text('Iniciar sesión'),
                      onPressed: _loginWithCedula,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
