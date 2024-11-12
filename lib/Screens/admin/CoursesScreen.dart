import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'SubjectsByCourseScreen.dart';
// Pantalla de lista de cursos 
class CoursesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      
      navigationBar: CupertinoNavigationBar(
        middle: Text('Cursos'),
      ),
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

          var courses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index].data() as Map<String, dynamic>;
              String courseId = courses[index].id;

              return CupertinoListTile(
                title: Text(
                  course['nombre_curso'] ?? 'Curso Sin Nombre',
                  style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                ),
                trailing: Icon(CupertinoIcons.chevron_forward),
                onTap: () {
                  // Navega a SubjectsByCourseScreen y pasa el courseId como parámetro
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      maintainState: false,
                      builder: (context) => SubjectsByCourseScreen(courseId: courseId),
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