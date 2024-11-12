import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentsListScreen extends StatefulWidget {
  @override
  _StudentsListScreenState createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  List<Map<String, dynamic>> assignedCourses = [];
  Map<String, List<Map<String, dynamic>>> studentsByCourse = {};
  Map<String, bool> attendanceStatus = {}; // Para guardar el estado de asistencia de cada estudiante
  Map<String, bool> expandedSections = {}; // Controla el estado de expansión de cada sección
  bool isLoading = true;
  String teacherCedula = '';
  String teacherName = ''; // Guardará el nombre del profesor

  @override
  void initState() {
    super.initState();
    _fetchTeacherCedulaAndStudents();
  }

  Future<void> _fetchTeacherCedulaAndStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      try {
        // Obtener la cédula y nombre del profesor
        QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('uid', isEqualTo: uid)
            .get();

        if (teacherSnapshot.docs.isNotEmpty) {
          DocumentSnapshot teacherDoc = teacherSnapshot.docs.first;
          teacherCedula = teacherDoc['cedula'] ?? 'No disponible';
          teacherName = teacherDoc['nombre'] ?? 'No disponible';

          // Obtener las materias del profesor
          QuerySnapshot materiasSnapshot = await FirebaseFirestore.instance
              .collection('materias')
              .where('profesorId', isEqualTo: teacherCedula)
              .get();

          for (var materiaDoc in materiasSnapshot.docs) {
            String courseId = materiaDoc['courseId'];
            String materiaName = materiaDoc['nombre'];

            // Inicializar la sección como contraída
            expandedSections[materiaName] = false;

            // Obtener estudiantes por curso
            QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
                .collection('estudiantes')
                .where('curso_id', isEqualTo: courseId)
                .get();

            List<Map<String, dynamic>> students = studentSnapshot.docs
                .map((studentDoc) => {
                      'id': studentDoc.id,
                      'nombre': studentDoc['nombre'],
                      'curso': studentDoc['curso_id'] ?? 'Curso no disponible', // Ajusta según el nombre del campo
                    })
                .toList();

            studentsByCourse[materiaName] = students;
          }
        } else {
          print("No se encontró el profesor.");
        }
      } catch (e) {
        print("Error al obtener la cédula y estudiantes: $e");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveAttendance() async {
    final attendanceCollection = FirebaseFirestore.instance.collection('asistencia');

    try {
      for (var entry in studentsByCourse.entries) {
        String materiaName = entry.key;
        List<Map<String, dynamic>> students = entry.value;

        for (var student in students) {
          String studentId = student['id'];
          String studentName = student['nombre'];
          String courseName = student['curso'];
          bool isPresent = attendanceStatus[studentId] ?? false;

          await attendanceCollection.add({
            'curso': courseName,
            'materia': materiaName,
            'estudiante': studentName,
            'profesor': teacherName,
            'asistencia': isPresent ? 'presente' : 'ausente',
            'fecha': Timestamp.now(), // Marca la fecha y hora de la asistencia
          });
        }
      }

      // Mostrar un mensaje de éxito
      showDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text("Asistencia Guardada"),
          content: Text("La asistencia ha sido guardada exitosamente."),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );

      // Resetear el estado de asistencia
      setState(() {
        attendanceStatus.clear();
      });
    } catch (e) {
      print("Error al guardar la asistencia: $e");
      // Manejar errores (mostrar mensaje, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Asistencia de Estudiantes"),
      ),
      child: SafeArea(
        child: isLoading
            ? Center(child: CupertinoActivityIndicator())
            : studentsByCourse.isEmpty
                ? Center(child: Text('No hay estudiantes registrados.'))
                : ListView(
                    children: studentsByCourse.entries.map((entry) {
                      String materiaName = entry.key;
                      List<Map<String, dynamic>> students = entry.value;
                      bool isExpanded = expandedSections[materiaName] ?? false;

                      return Column(
                        children: [
                          CupertinoListTile(
                            title: Text(materiaName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            trailing: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Icon(isExpanded
                                  ? CupertinoIcons.chevron_up
                                  : CupertinoIcons.chevron_down),
                              onPressed: () {
                                setState(() {
                                  expandedSections[materiaName] = !isExpanded;
                                });
                              },
                            ),
                            onTap: () {
                              setState(() {
                                expandedSections[materiaName] = !isExpanded;
                              });
                            },
                          ),
                          if (isExpanded)
                            ...students.map((student) {
                              String studentId = student['id'];
                              String studentName = student['nombre'];
                              bool isChecked = attendanceStatus[studentId] ?? false;

                              return CupertinoListTile(
                                title: Text(studentName),
                                trailing: CupertinoSwitch(
                                  value: isChecked,
                                  onChanged: (bool value) {
                                    setState(() {
                                      attendanceStatus[studentId] = value;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          if (isExpanded)
                            CupertinoButton.filled(
                              child: Text("Guardar Asistencia"),
                              onPressed: _saveAttendance,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
