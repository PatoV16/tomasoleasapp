import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollStudentsScreen extends StatefulWidget {
  @override
  _EnrollStudentsScreenState createState() => _EnrollStudentsScreenState();
}

class _EnrollStudentsScreenState extends State<EnrollStudentsScreen> {
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController etniaController = TextEditingController();
  final TextEditingController representanteController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();

  DateTime? fechaNacimiento;
  String? selectedCursoId; // ID del curso seleccionado
  List<DropdownMenuItem<String>> cursos = []; // Lista de cursos para el dropdown

  @override
  void initState() {
    super.initState();
    _fetchCursos(); // Cargar los cursos al iniciar la pantalla
  }

  Future<void> _fetchCursos() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('cursos').get();
    setState(() {
      cursos = querySnapshot.docs.map((doc) {
        return DropdownMenuItem(
          value: doc.id, // Guardamos el ID del documento
          child: Text(doc['nombre_curso'] ?? 'Curso sin nombre'), // Muestra el nombre del curso
        );
      }).toList();
    });
  }

  Future<void> _addStudentToFirebase(BuildContext context) async {
    if (cedulaController.text.isEmpty ||
        nombreController.text.isEmpty ||
        fechaNacimiento == null ||
        selectedCursoId == null) { // Validación del curso seleccionado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, llena todos los campos obligatorios')),
      );
      return;
    }

    int edad = DateTime.now().year - fechaNacimiento!.year;

    try {
      await FirebaseFirestore.instance.collection('estudiantes').doc(cedulaController.text).set({
        'nombre': nombreController.text,
        'cedula': cedulaController.text,
        'fecha_nacimiento': fechaNacimiento,
        'edad': edad,
        'etnia': etniaController.text,
        'representante': representanteController.text,
        'telefono_representante': telefonoController.text,
        'curso_id': selectedCursoId, // Guardar el ID del curso seleccionado
        'role': 'estudiante'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estudiante registrado exitosamente')),
      );

      cedulaController.clear();
      nombreController.clear();
      edadController.clear();
      etniaController.clear();
      representanteController.clear();
      telefonoController.clear();
      selectedCursoId = null;
      fechaNacimiento = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el estudiante: $e')),
      );
    }
  }

  void _selectFechaNacimiento(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        fechaNacimiento = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matricular Estudiantes')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCursoId,
              items: cursos,
              hint: Text('Selecciona un curso'),
              onChanged: (value) {
                setState(() {
                  selectedCursoId = value;
                });
              },
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
            CupertinoButton(
              child: Text(fechaNacimiento == null
                  ? 'Fecha de Nacimiento'
                  : fechaNacimiento!.toLocal().toString().split(' ')[0]),
              onPressed: () => _selectFechaNacimiento(context),
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: etniaController,
              placeholder: 'Etnia',
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: representanteController,
              placeholder: 'Representante',
            ),
            SizedBox(height: 8),
            CupertinoTextField(
              controller: telefonoController,
              placeholder: 'Teléfono del Representante',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            CupertinoButton.filled(
              child: Text('Registrar Estudiante'),
              onPressed: () => _addStudentToFirebase(context),
            ),
          ],
        ),
      ),
    );
  }
}
