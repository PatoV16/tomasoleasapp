import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tomasoleasapp/Screens/admin/MessagesScreen.dart';
import 'package:tomasoleasapp/Screens/admin/uploadSchedule.dart';

import 'AnnouncementsScreen.dart';
import 'CoursesScreen.dart';
import 'GenerateCoursesScreen.dart';
import 'RegisterTeachersScreen.dart';
import 'StudentsByCourseScreen.dart';
import 'StudentBulletinScreen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _sections = [
    GenerateCoursesScreen(),
    StudentsByCourseScreen(),
    RegisterTeachersScreen(),
    AnnouncementsScreen(),
    CoursesScreen(),
    StudentBulletinScreen(),
    UploadScheduleScreen(),
    MessagesScreen(), // Añade la pantalla de Mensajes aquí
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Administrador - Panel de Control'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.person_circle),
          onPressed: () {
            // Acción para el perfil del administrador
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
                        const NavigationRailDestination(
                          icon: Icon(CupertinoIcons.book_solid),
                          label: Text('Generar Cursos'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.person_2_fill),
                          label: Text('Estudiantes por Curso'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.person_crop_circle_badge_plus),
                          label: Text('Registrar Profesores'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.bell_solid),
                          label: Text('Comunicados'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.doc_append),
                          label: Text('Materias por curso'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.news_solid),
                          label: Text('Boletín de Estudiante'),
                        ),
                         NavigationRailDestination(
                          icon: Icon(CupertinoIcons.news_solid),
                          label: Text('Subir Horarios'),
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
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.book_solid),
                    label: 'Cursos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_2_fill),
                    label: 'Estudiantes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_crop_circle_badge_plus),
                    label: 'Profesores',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.bell_solid),
                    label: 'Comunicados',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.doc_append),
                    label: 'Materias',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.news_solid),
                    label: 'Boletín',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.news_solid),
                    label: 'Horarios',
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
