import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin/StudentsListScreen.dart';

class CoursesAssignedScreen extends StatefulWidget {
  @override
  _CoursesAssignedScreenState createState() => _CoursesAssignedScreenState();
}

class _CoursesAssignedScreenState extends State<CoursesAssignedScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> assignedCourses = [];
  bool isLoading = true;
  String teacherCedula = '';

  @override
  void initState() {
    super.initState();
    _fetchTeacherCedulaAndCourses();
  }
Future<void> _fetchTeacherCedulaAndCourses() async {
  if (user != null) {
    final uid = user!.uid; // Obtener el UID del usuario logueado
    print("UID del usuario: $uid");

    try {
      // Obtener la cédula del profesor filtrando por UID
      QuerySnapshot teacherSnapshot = await FirebaseFirestore.instance
          .collection('profesores')
          .where('uid', isEqualTo: uid)
          .get();

      if (teacherSnapshot.docs.isNotEmpty) {
        DocumentSnapshot teacherDoc = teacherSnapshot.docs.first;
        teacherCedula = teacherDoc['cedula'] ?? 'No disponible'; // Extraer la cédula

        // Ahora, usar la cédula para obtener las materias
        QuerySnapshot materiasSnapshot = await FirebaseFirestore.instance
            .collection('materias')
            .where('profesorId', isEqualTo: teacherCedula)
            .get();

        // Recorremos las materias y buscamos los cursos
        for (var materiaDoc in materiasSnapshot.docs) {
          String courseId = materiaDoc['courseId']; // Obtener el ID del curso

          // Ahora, obtenemos los detalles del curso
          DocumentSnapshot courseDoc = await FirebaseFirestore.instance
              .collection('cursos')
              .doc(courseId)
              .get();

          // Agregamos la información a la lista si el curso existe
          if (courseDoc.exists) {
            assignedCourses.add({
              'courseName': courseDoc['nombre_curso'], // Asumiendo que tienes este campo
              'courseId': courseId,
              'materiaName': materiaDoc['nombre'], // Asumiendo que tienes este campo
            });
          }
        }
      } else {
        print("No se encontró el profesor.");
      }
    } catch (e) {
      print("Error al obtener los cursos asignados: $e");
    }
  } else {
    print("No hay usuario logueado.");
  }

  setState(() {
    isLoading = false; // Actualizamos el estado para ocultar el cargador
  });
}


 @override
Widget build(BuildContext context) {
  return SafeArea(
    child: isLoading
        ? Center(child: CupertinoActivityIndicator())
        : assignedCourses.isEmpty
            ? Center(child: Text('No hay cursos asignados.'))
            : ListView.builder(
                itemCount: assignedCourses.length,
                itemBuilder: (context, index) {
                  final course = assignedCourses[index];

                  return CupertinoListTile(
                    title: Text(
                      course['courseName'] ?? 'Curso Sin Nombre',
                      style: TextStyle(
                        fontSize: 16, // Tamaño de letra más pequeño
                        color: CupertinoColors.black, // Color negro
                        fontWeight: FontWeight.w500, // Peso de la letra semi-negrita
                      ),
                    ),
                    subtitle: Text('Materia: ${course['materiaName']}'),
                    trailing: Icon(CupertinoIcons.chevron_forward),
                    onTap: () {
                      // Al hacer clic, navega a la lista de estudiantes para ese curso
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          maintainState: false,
                          builder: (context) => StudentsListScreen(courseId: course['courseId']),
                        ),
                      );
                    },
                  );
                },
              ),
  );
}


}
