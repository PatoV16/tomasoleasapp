import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadGradesScreen extends StatefulWidget {
  @override
  _UploadGradesScreenState createState() => _UploadGradesScreenState();
}
class _UploadGradesScreenState extends State<UploadGradesScreen> {
  Map<String, Map<String, Map<String, dynamic>>> gradesByStudent = {}; // Agrupa por materia y estudiante
  Map<String, bool> expandedSections = {};
  bool isLoading = true;
  String teacherCedula = '';

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
        QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
            .collection('profesores')
            .where('uid', isEqualTo: uid)
            .get();

        if (teacherSnapshot.docs.isNotEmpty) {
          DocumentSnapshot teacherDoc = teacherSnapshot.docs.first;
          teacherCedula = teacherDoc['cedula'] ?? 'No disponible';

          QuerySnapshot materiasSnapshot = await FirebaseFirestore.instance
              .collection('materias')
              .where('profesorId', isEqualTo: teacherCedula)
              .get();

          for (var materiaDoc in materiasSnapshot.docs) {
            String materiaId = materiaDoc.id;
            String materiaName = materiaDoc['nombre'];

            expandedSections[materiaName] = false;
            gradesByStudent[materiaName] = {}; // Inicializa un mapa para cada materia

            QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
                .collection('estudiantes')
                .where('curso_id', isEqualTo: materiaDoc['courseId'])
                .get();

            for (var studentDoc in studentSnapshot.docs) {
              String studentId = studentDoc.id;
              String studentName = studentDoc['nombre'];

              gradesByStudent[materiaName]![studentId] = {
                'nombre': studentName,
                'primerTrimestre': 0.0,
                'segundoTrimestre': 0.0,
                'tercerTrimestre': 0.0,
                'evaluacionFinal': 0.0, // Nuevo campo
                'supletorio': 0.0, // Nuevo campo
              };
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

  Future<void> _saveGrades() async {
    final gradesCollection = FirebaseFirestore.instance.collection('calificaciones');

    try {
      for (var materiaEntry in gradesByStudent.entries) {
        String materiaName = materiaEntry.key;
        Map<String, Map<String, dynamic>> students = materiaEntry.value;

        for (var studentEntry in students.entries) {
          String studentId = studentEntry.key;
          Map<String, dynamic> gradeData = studentEntry.value;

          double primerTrim = gradeData['primerTrimestre'] ?? 0.0;
          double segundoTrim = gradeData['segundoTrimestre'] ?? 0.0;
          double tercerTrim = gradeData['tercerTrimestre'] ?? 0.0;
          double evaluacionFinal = gradeData['evaluacionFinal'] ?? 0.0;
          double supletorio = gradeData['supletorio'] ?? 0.0;

          // Validación de las calificaciones
          if (primerTrim < 0 || primerTrim > 10 ||
              segundoTrim < 0 || segundoTrim > 10 ||
              tercerTrim < 0 || tercerTrim > 10 ||
              evaluacionFinal < 0 || evaluacionFinal > 10 ||
              supletorio < 0 || supletorio > 10) {
            showDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: Text("Error de Calificación"),
                content: Text("Las calificaciones deben estar entre 0 y 10."),
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
            return;
          }

          await gradesCollection.add({
            'estudianteId': studentId,
            'materia': materiaName,
            'nombreEstudiante': gradeData['nombre'],
            'primerTrimestre': primerTrim,
            'segundoTrimestre': segundoTrim,
            'tercerTrimestre': tercerTrim,
            'evaluacionFinal': evaluacionFinal,
            'supletorio': supletorio,
            'fecha': Timestamp.now(),
          });
        }
      }

      showDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text("Calificaciones Guardadas"),
          content: Text("Las calificaciones han sido guardadas exitosamente."),
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

      setState(() {
        gradesByStudent.updateAll((materiaName, students) => {
          for (var studentEntry in students.entries)
            studentEntry.key: {
              'nombre': studentEntry.value['nombre'],
              'primerTrimestre': 0.0,
              'segundoTrimestre': 0.0,
              'tercerTrimestre': 0.0,
              'evaluacionFinal': 0.0,
              'supletorio': 0.0,
            }
        });
      });
    } catch (e) {
      print("Error al guardar las calificaciones: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Subir Calificaciones"),
      ),
      child: SafeArea(
        child: isLoading
            ? Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: expandedSections.keys.map((materiaName) {
                    bool isExpanded = expandedSections[materiaName] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoListTile(
                            title: Text(
                              materiaName,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
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
                          ),
                          if (isExpanded)
                            Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(16.0),
                              margin: EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: gradesByStudent[materiaName]!.entries.map((entry) {
                                  String studentId = entry.key;
                                  Map<String, dynamic> studentData = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentData['nombre'],
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                        ),
                                        SizedBox(height: 8.0),
                                        _buildGradeRow("1er Trim.", studentData, 'primerTrimestre'),
                                        _buildGradeRow("2do Trim.", studentData, 'segundoTrimestre'),
                                        _buildGradeRow("3er Trim.", studentData, 'tercerTrimestre'),
                                        _buildGradeRow("Evaluación Final", studentData, 'evaluacionFinal'), // Nuevo campo
                                        _buildGradeRow("Supletorio", studentData, 'supletorio'), // Nuevo campo
                                        Divider(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (isExpanded)
                            CupertinoButton.filled(
                              child: Text("Guardar Calificaciones"),
                              onPressed: _saveGrades,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildGradeRow(String label, Map<String, dynamic> studentData, String gradeKey) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Expanded(
          child: CupertinoTextField(
            keyboardType: TextInputType.number,
            placeholder: "Nota",
            onChanged: (value) {
              setState(() {
                studentData[gradeKey] = double.tryParse(value) ?? 0.0;
              });
            },
          ),
        ),
      ],
    );
  }
}
