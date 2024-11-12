import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseScreenStudent extends StatefulWidget {
  final String studentId;
  final String cursoId;

  CourseScreenStudent({required this.studentId, required this.cursoId});

  @override
  _CourseScreenStudentState createState() => _CourseScreenStudentState();
}

class _CourseScreenStudentState extends State<CourseScreenStudent> {
  List<String> _subjects = [];
  String _courseName = ''; // Variable para almacenar el nombre del curso

  @override
  void initState() {
    super.initState();
    _fetchCourseName(widget.cursoId); // Obtiene el nombre del curso
    _fetchSubjects(widget.cursoId); // Obtiene las materias del curso
  }

  // Función para obtener el nombre del curso
  Future<void> _fetchCourseName(String courseId) async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('cursos')
          .doc(courseId)
          .get();

      if (courseDoc.exists) {
        setState(() {
          _courseName = courseDoc.get('nombre_curso'); // Campo de nombre del curso
        });
      } else {
        print('El curso no existe');
      }
    } catch (e) {
      print('Error al obtener el nombre del curso: $e');
    }
  }

  // Función para obtener las materias del curso
  Future<void> _fetchSubjects(String courseId) async {
    try {
      final subjectSnapshot = await FirebaseFirestore.instance
          .collection('materias')
          .where('courseId', isEqualTo: courseId)
          .get();

      setState(() {
        _subjects = subjectSnapshot.docs
            .map((doc) => doc.get('nombre'))
            .cast<String>()
            .toList();
      });
    } catch (e) {
      print('Error al obtener las materias: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Materias del Curso')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Muestra el nombre del curso asignado
            if (_courseName.isNotEmpty)
              Text(
                'Curso asignado: $_courseName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 20),
            Expanded(
              child: _subjects.isNotEmpty
                  ? ListView.builder(
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_subjects[index]),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No hay materias disponibles para este curso.',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
