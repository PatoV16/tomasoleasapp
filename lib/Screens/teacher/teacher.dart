import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tomasoleasapp/Screens/teacher/MessagesScreenTeacher.dart';

import 'CoursesAssignedScreen.dart';
import 'GradesPerStudentScreen.dart';
import 'StudentsListScreen.dart';
import 'TeacherProfileScreen.dart';
import 'UploadGradesScreen.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _sections;
  String teacherName = 'Profesor'; // Valor predeterminado para el título
  final user = FirebaseAuth.instance.currentUser; // Usuario actual

  @override
  void initState() {
    super.initState();

    _sections = [
      CoursesAssignedScreen(),
      StudentsListScreen(),
      GradesPerStudentScreen(),
      UploadGradesScreen(),
      MessagesScreenTeacher(),
    ];

    // Llama al método para obtener el nombre del profesor
    _fetchTeacherName();
  }

  Future<void> _fetchTeacherName() async {
  if (user != null) {
    final uid = user!.uid;
    try {
      // Busca en toda la colección 'profesores' para encontrar el documento que coincida con el uid
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('profesores')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si se encuentra al menos un documento
        DocumentSnapshot doc = querySnapshot.docs.first;
        setState(() {
          teacherName = doc['nombre'] ?? 'Profesor'; // Obtiene el nombre
        });
      } else {
        print("No se encontró el profesor con el UID especificado.");
      }
    } catch (e) {
      print("Error al obtener el nombre del profesor: $e");
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('$teacherName - Panel de Control'), // Muestra el nombre del profesor
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.person_circle),
          onPressed: () {
            // Acción para el perfil del profesor
            Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TeacherProfileScreen(),
      ),
    );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (MediaQuery.of(context).size.width > 600) ...[
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.book),
                          label: Text('Cursos Asignados'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.person_2),
                          label: Text('Lista de Estudiantes'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.doc_text),
                          label: Text('Notas por Estudiante'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.cloud_upload),
                          label: Text('Subir Calificaciones'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.chat_bubble_2_fill),
                          label: Text('Mensajes'), // Añade el icono y etiqueta de Mensajes
                        ),
                      ],
                    ),
                    VerticalDivider(thickness: 1, width: 1),
                  ],
                  Expanded(child: _sections[_selectedIndex]),
                ],
              ),
            ),
            if (MediaQuery.of(context).size.width <= 600) ...[
              CupertinoTabBar(
                currentIndex: _selectedIndex,
                onTap: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.book),
                    label: 'Cursos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_2),
                    label: 'Estudiantes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.doc_text),
                    label: 'Notas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.cloud_upload),
                    label: 'Subir Calificaciones',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chat_bubble_2_fill),
                    label: 'Mensajes', // Añade la opción de Mensajes en el TabBar
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}





