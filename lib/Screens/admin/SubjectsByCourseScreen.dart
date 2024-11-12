import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'SubjectDetailScreen.dart';
class SubjectsByCourseScreen extends StatelessWidget {
  final String courseId; // Agrega el ID del curso como parámetro

  SubjectsByCourseScreen({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      
      navigationBar: CupertinoNavigationBar(
        middle: Text('Materias del Curso'),
      ),
      child: FutureBuilder<QuerySnapshot>(
        // Filtra las materias para que solo traiga las que pertenecen al curso con el courseId proporcionado
        future: FirebaseFirestore.instance
            .collection('materias')
            .where('courseId', isEqualTo: courseId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CupertinoActivityIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No hay materias disponibles para este curso.'),
            );
          }

          var subjects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              var subject = subjects[index].data() as Map<String, dynamic>;
              String subjectId = subjects[index].id;

              return CupertinoListTile(
                title: Text(
                  subject['nombre'] ?? 'Materia Sin Nombre',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(CupertinoIcons.chevron_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => SubjectDetailsScreen(subjectId: subjectId),
                      maintainState: false
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}