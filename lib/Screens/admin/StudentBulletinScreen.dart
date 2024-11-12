import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class StudentBulletinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Boletín de Estudiantes por Curso'),
      ),
      child: Material( // Asegúrate de envolver con Material
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('cursos').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No hay cursos disponibles.'),
              );
            }

            var cursos = snapshot.data!.docs;

            return ListView.builder(
              itemCount: cursos.length,
              itemBuilder: (context, index) {
                var curso = cursos[index].data() as Map<String, dynamic>;
                String courseName = curso['nombre_curso'] ?? 'Curso sin Nombre';
                String courseId = cursos[index].id;

                return ExpansionTile(
                  title: Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('estudiantes')
                          .where('curso_id', isEqualTo: courseId) // Filtramos por curso
                          .get(),
                      builder: (context, studentSnapshot) {
                        if (studentSnapshot.connectionState == ConnectionState.waiting) {
                          return CupertinoActivityIndicator();
                        }
                        if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay estudiantes en este curso.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        var estudiantes = studentSnapshot.data!.docs;

                        return Column(
                          children: estudiantes.map((studentDoc) {
                            var student = studentDoc.data() as Map<String, dynamic>;
                            String studentName = student['nombre'] ?? 'Estudiante sin Nombre';
                            String studentId = studentDoc.id;

                            return ListTile(
                              title: Text(studentName),
                              trailing: CupertinoButton(
                                child: Text(
                                  'Ver Reporte',
                                  style: TextStyle(color: CupertinoColors.activeBlue),
                                ),
                                onPressed: () async {
                                  await _generateStudentReport(studentId, studentName, courseName);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _generateStudentReport(String studentId, String studentName, String courseName) async {
    try {
      // Obtener las calificaciones del estudiante
      QuerySnapshot gradesSnapshot = await FirebaseFirestore.instance
          .collection('calificaciones')
          .where('estudianteId', isEqualTo: studentId)
          .get();

      // Crear el archivo Excel
      var excel = Excel.createExcel(); // Crear un libro de Excel
      Sheet sheet = excel['Sheet1'];

      // Añadir encabezados de las columnas
      sheet
        ..cell(CellIndex.indexByString("A1")).value = TextCellValue('Estudiante')
        ..cell(CellIndex.indexByString("B1")).value = TextCellValue('Materia')
        ..cell(CellIndex.indexByString("C1")).value = TextCellValue('1er Trimestre')
        ..cell(CellIndex.indexByString("D1")).value = TextCellValue('2do Trimestre')
        ..cell(CellIndex.indexByString("E1")).value = TextCellValue('3er Trimestre')
        ..cell(CellIndex.indexByString("F1")).value = TextCellValue('Evaluación Final')
        ..cell(CellIndex.indexByString("G1")).value = TextCellValue('Supletorio')
        ..cell(CellIndex.indexByString("H1")).value = TextCellValue('Promedio Anual');

      int row = 2; // Comenzar a escribir en la fila 2 (debido a los encabezados)

      // Añadir las calificaciones
      for (var gradeDoc in gradesSnapshot.docs) {
        var gradeData = gradeDoc.data() as Map<String, dynamic>;
        String materia = gradeData['materia'] ?? 'Materia desconocida';
        double primerTrimestre = gradeData['primerTrimestre'] ?? 0.0;
        double segundoTrimestre = gradeData['segundoTrimestre'] ?? 0.0;
        double tercerTrimestre = gradeData['tercerTrimestre'] ?? 0.0;
        double evaluacionFinal = gradeData['evaluacionFinal'] ?? 0.0;
        double supletorio = gradeData['supletorio'] ?? 0.0;

        // Calcular el promedio de los tres trimestres
        double promedioTrimestres = (primerTrimestre + segundoTrimestre + tercerTrimestre) / 3;

        // Calcular el promedio anual
        double promedioAnual = (promedioTrimestres + evaluacionFinal + supletorio) / 3;

        sheet
          ..cell(CellIndex.indexByString("A$row")).value = TextCellValue(studentName)
          ..cell(CellIndex.indexByString("B$row")).value = TextCellValue(materia)
          ..cell(CellIndex.indexByString("C$row")).value = TextCellValue(primerTrimestre.toString())
          ..cell(CellIndex.indexByString("D$row")).value = TextCellValue(segundoTrimestre.toString())
          ..cell(CellIndex.indexByString("E$row")).value = TextCellValue(tercerTrimestre.toString())
          ..cell(CellIndex.indexByString("F$row")).value = TextCellValue(evaluacionFinal.toString())
          ..cell(CellIndex.indexByString("G$row")).value = TextCellValue(supletorio.toString())
          ..cell(CellIndex.indexByString("H$row")).value = TextCellValue(promedioAnual.toStringAsFixed(2));

        row++;
      }

      // Convertir el archivo a bytes
      var bytes = excel.encode();

      // Crear el enlace de descarga
      final blob = html.Blob([Uint8List.fromList(bytes!)]); 
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = 'reporte_${studentId}_$courseName.xlsx'
        ..click();
      html.Url.revokeObjectUrl(url);

      print("Archivo Excel generado y descargado.");
    } catch (e) {
      print("Error al generar el reporte del estudiante: $e");
    }
  }
}
