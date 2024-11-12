import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:html' as html; // Para manejar la descarga del archivo en Web

class GradesPerStudentScreen extends StatefulWidget {
  @override
  _GradesPerStudentScreenState createState() =>
      _GradesPerStudentScreenState();
}

class _GradesPerStudentScreenState extends State<GradesPerStudentScreen> {
  bool isLoading = true;
  String teacherCedula = '';
  Map<String, Map<String, List<Map<String, dynamic>>>> gradesByCourseAndSubject = {};
  Map<String, String> courseNames = {}; // Mapa para almacenar los nombres de los cursos

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
        // Obtener la cédula del profesor autenticado
        QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('uid', isEqualTo: uid)
            .get();

        if (teacherSnapshot.docs.isNotEmpty) {
          DocumentSnapshot teacherDoc = teacherSnapshot.docs.first;
          teacherCedula = teacherDoc['cedula'] ?? 'No disponible';

          // Obtener materias asignadas al profesor autenticado
          QuerySnapshot materiasSnapshot = await FirebaseFirestore.instance
              .collection('materias')
              .where('profesorId', isEqualTo: teacherCedula)
              .get();

          for (var materiaDoc in materiasSnapshot.docs) {
            String materiaName = materiaDoc['nombre'];
            String courseId = materiaDoc['courseId'];

            // Obtener el nombre del curso usando courseId
            if (!courseNames.containsKey(courseId)) {
              DocumentSnapshot courseDoc = await FirebaseFirestore.instance
                  .collection('cursos')
                  .doc(courseId)
                  .get();
              courseNames[courseId] = courseDoc['nombre_curso'] ?? 'Curso desconocido';
            }

            // Obtener estudiantes en el curso correspondiente a la materia
            QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
                .collection('estudiantes')
                .where('curso_id', isEqualTo: courseId)
                .get();

            for (var studentDoc in studentSnapshot.docs) {
              String studentId = studentDoc.id;
              String studentName = studentDoc['nombre'];

              // Obtener calificaciones de cada estudiante en la materia actual
              QuerySnapshot gradesSnapshot = await FirebaseFirestore.instance
                  .collection('calificaciones')
                  .where('estudianteId', isEqualTo: studentId)
                  .where('materia', isEqualTo: materiaName)
                  .get();

              // Inicializar las calificaciones por defecto
              double primerTrimestre = 0.0;
              double segundoTrimestre = 0.0;
              double tercerTrimestre = 0.0;

              if (gradesSnapshot.docs.isNotEmpty) {
                var gradeDoc = gradesSnapshot.docs.first;
                primerTrimestre = gradeDoc['primerTrimestre'] ?? 0.0;
                segundoTrimestre = gradeDoc['segundoTrimestre'] ?? 0.0;
                tercerTrimestre = gradeDoc['tercerTrimestre'] ?? 0.0;
              }

              // Agrupar los estudiantes por curso y materia
              if (!gradesByCourseAndSubject.containsKey(courseId)) {
                gradesByCourseAndSubject[courseId] = {};
              }
              if (!gradesByCourseAndSubject[courseId]!.containsKey(materiaName)) {
                gradesByCourseAndSubject[courseId]![materiaName] = [];
              }

              gradesByCourseAndSubject[courseId]![materiaName]!.add({
                'nombre': studentName,
                'primerTrimestre': primerTrimestre,
                'segundoTrimestre': segundoTrimestre,
                'tercerTrimestre': tercerTrimestre,
              });
            }
          }
        } else {
          print("No se encontró el profesor.");
        }
      } catch (e) {
        print("Error al obtener los datos: $e");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _generateExcel(List<Map<String, dynamic>> students, String courseName) async {
    try {
      var excel = Excel.createExcel(); // Crear un libro de Excel
      Sheet sheet = excel['Sheet1'];

      // Añadir encabezados de las columnas
      sheet
        ..cell(CellIndex.indexByString("A1")).value = TextCellValue('Nombre')
        ..cell(CellIndex.indexByString("B1")).value = TextCellValue('1er Trimestre')
        ..cell(CellIndex.indexByString("C1")).value = TextCellValue('2do Trimestre')
        ..cell(CellIndex.indexByString("D1")).value = TextCellValue('3er Trimestre');

      // Añadir los datos de los estudiantes
      for (var i = 0; i < students.length; i++) {
        var student = students[i];

        // Asignar valores de cada estudiante a las celdas correspondientes
        sheet
          ..cell(CellIndex.indexByString("A${i + 2}")).value = TextCellValue(student['nombre'])
          ..cell(CellIndex.indexByString("B${i + 2}")).value = TextCellValue(student['primerTrimestre'].toString())
          ..cell(CellIndex.indexByString("C${i + 2}")).value = TextCellValue(student['segundoTrimestre'].toString())
          ..cell(CellIndex.indexByString("D${i + 2}")).value = TextCellValue(student['tercerTrimestre'].toString());
      }

      // Convertir el archivo a bytes
      var bytes = excel.encode();

      // Crear el enlace de descarga
      final blob = html.Blob([Uint8List.fromList(bytes!)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'reporte_$courseName.xlsx'
        ..click();
      html.Url.revokeObjectUrl(url);

      print("Archivo Excel generado y descargado.");
    } catch (e) {
      print("Error al generar el Excel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Calificaciones por Estudiante y Materia"),
      ),
      child: isLoading
          ? Center(child: CupertinoActivityIndicator())
          : ListView(
              children: gradesByCourseAndSubject.entries.map((courseEntry) {
                String courseId = courseEntry.key;
                String courseName = courseNames[courseId] ?? 'Curso desconocido';
                var subjects = courseEntry.value;

                return Material(
                  child: ExpansionTile(
                    title: Text("Curso: $courseName"),
                    children: subjects.entries.map((subjectEntry) {
                      String materiaName = subjectEntry.key;
                      List<Map<String, dynamic>> students = subjectEntry.value;

                      return Column(
                        children: [
                          Text("Materia: $materiaName", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...students.map((student) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Estudiante: ${student['nombre']}"),
                                    Text("Primer Trimestre: ${student['primerTrimestre']}"),
                                    Text("Segundo Trimestre: ${student['segundoTrimestre']}"),
                                    Text("Tercer Trimestre: ${student['tercerTrimestre']}"),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 10),
                          CupertinoButton(
                            color: const Color.fromARGB(255, 218, 128, 227),
                            child: Text("Ver Reporte de Materia"),
                            onPressed: () {
                              _showDownloadOptions(context, students, '$courseName - $materiaName');
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _showDownloadOptions(BuildContext context, List<Map<String, dynamic>> students, String courseName) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Descargar Reporte'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text('Descargar Excel'),
            onPressed: () async {
              await _generateExcel(students, courseName);
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
