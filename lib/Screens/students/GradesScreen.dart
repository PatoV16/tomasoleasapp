import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GradesScreen extends StatelessWidget {
  final String studentId;  // Recibimos la cédula del estudiante como parámetro

  GradesScreen({required this.studentId});

  // Función para obtener las calificaciones del estudiante desde Firestore
  Future<List<Map<String, dynamic>>> _fetchGrades(String studentId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('calificaciones')
          .where('estudianteId', isEqualTo: studentId)
          .get();

      // Mapeamos los datos para obtener la materia y las calificaciones
      List<Map<String, dynamic>> grades = querySnapshot.docs.map((doc) {
        return {
          'materia': doc.get('materia'),
          'primerTrimestre': doc.get('primerTrimestre'),
          'segundoTrimestre': doc.get('segundoTrimestre'),
          'tercerTrimestre': doc.get('tercerTrimestre'),
        };
      }).toList();

      return grades;
    } catch (e) {
      print('Error al obtener las calificaciones: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchGrades(studentId),  // Llamamos a la función que obtiene las calificaciones
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Ocurrió un error al cargar las calificaciones.'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay calificaciones disponibles.'));
        } else {
          final grades = snapshot.data!;

          return ListView.builder(
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListTile(
                  title: Text(grade['materia']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Primer Trimestre: ${grade['primerTrimestre']}'),
                      Text('Segundo Trimestre: ${grade['segundoTrimestre']}'),
                      Text('Tercer Trimestre: ${grade['tercerTrimestre']}'),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
