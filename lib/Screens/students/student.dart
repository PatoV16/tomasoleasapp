import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tomasoleasapp/Screens/students/CoursesScreen.dart';
import 'package:tomasoleasapp/Screens/students/GradesScreen.dart';
import 'ScheduleScreen.dart';
class AcademicDashboard extends StatefulWidget {
   final String nombreEstudiante;
  final String studentId;  // Nuevo atributo para el studentId
  final String cursoId;

  // Asegúrate de que el constructor reciba el nuevo atributo
  AcademicDashboard({required this.nombreEstudiante, required this.studentId, required this.cursoId});

  @override
  _AcademicDashboardState createState() => _AcademicDashboardState();
}

class _AcademicDashboardState extends State<AcademicDashboard> {
  int _selectedIndex = 0;
   late List<Widget> _sections;

  @override
  void initState() {
    super.initState();
    // Inicializar _sections utilizando los valores de widget.studentId y widget.cursoId
    _sections = [
      CourseScreenStudent(studentId: widget.studentId, cursoId: widget.cursoId),
      GradesScreen(studentId: widget.studentId),
      ScheduleScreen(),
      PerformanceScreen(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Bienvenido, ${widget.nombreEstudiante}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.person_circle),
          onPressed: () {
            // Acción para el perfil del usuario
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
                    // Menu lateral para tabletas y escritorio
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
                          label: Text('Asignaturas'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.chart_bar_square),
                          label: Text('Calificaciones'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.time),
                          label: Text('Horario'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(CupertinoIcons.graph_square),
                          label: Text('Rendimiento'),
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
              // Navigation bar para pantallas móviles
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
                    icon: Icon(CupertinoIcons.chart_bar_square),
                    label: 'Calificaciones',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.time),
                    label: 'Horario',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.graph_square),
                    label: 'Rendimiento',
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



class PerformanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Rendimiento Académico'),
    );
  }
}
