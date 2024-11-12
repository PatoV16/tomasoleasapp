import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'EnrollStudentsScreen.dart';
import 'ExcelUploader.dart';

class GenerateCoursesScreen extends StatelessWidget {
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController paraleloController = TextEditingController();
  final TextEditingController tutorController = TextEditingController();

  Future<void> _addCourseToFirebase(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('cursos').add({
        'id_curso': idController.text,
        'nombre_curso': nameController.text,
        'paralelo': paraleloController.text,
        'tutor': tutorController.text,
      });

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Curso creado exitosamente')),
      );

      // Limpiar los campos después de subir los datos
      idController.clear();
      nameController.clear();
      paraleloController.clear();
      tutorController.clear();
    } on FirebaseException catch (e) {
      // Maneja específicamente la excepción de Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el curso: ${e.message}')),
      );
    } catch (e) {
      // Maneja otras excepciones no específicas de Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error desconocido: $e')),
      );
    }
  }

  void showAddCourseSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Agregar Curso'),
        message: Column(
          children: [
            CupertinoTextField(
              controller: idController,
              placeholder: 'ID Curso',
            ),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Nombre del Curso',
            ),
            CupertinoTextField(
              controller: paraleloController,
              placeholder: 'Paralelo',
            ),
            CupertinoTextField(
              controller: tutorController,
              placeholder: 'Tutor',
            ),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              _addCourseToFirebase(context); // Llamada para agregar el curso a Firebase
              Navigator.pop(context);
            },
            child: Text('Crear Curso'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void showEnrollmentSheet(BuildContext context, String courseId) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            'Matricular Estudiantes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF5D6063)),
          ),
          message: Text(
            'Selecciona cómo deseas matricular a los estudiantes.',
            style: TextStyle(fontSize: 16, color: const Color(0xFF5D6063)),
          ),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                // Navegar a EnrollStudentsScreen
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => EnrollStudentsScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.person_add, color: CupertinoColors.activeBlue),
                  SizedBox(width: 8),
                  Text('Matricular manualmente'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                ExcelUploader().openFileExplorer(context, courseId);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(CupertinoIcons.doc, color: CupertinoColors.activeBlue),
                  SizedBox(width: 8),
                  Text('Subir nómina de estudiantes'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Text(
              'Cancelar',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void showAddSubjectSheet(BuildContext context, String courseId) {
    final TextEditingController subjectNameController = TextEditingController();
    final TextEditingController subjectCodeController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            'Registrar Materia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF5D6063)),
          ),
          message: Column(
            children: [
              CupertinoTextField(
                controller: subjectNameController,
                placeholder: 'Nombre de la Materia',
              ),
              CupertinoTextField(
                controller: subjectCodeController,
                placeholder: 'Código de la Materia',
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                try {
                  // Agregar materia a Firestore con referencia al curso
                  await FirebaseFirestore.instance.collection('materias').add({
                    'nombre': subjectNameController.text,
                    'codigo': subjectCodeController.text,
                    'courseId': courseId,
                  });
                  Navigator.pop(context); // Cierra el modal

                  // Mostrar confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Materia registrada exitosamente'),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);

                  // Mostrar error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.black,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                }
              },
              child: Text('Guardar Materia'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        );
      },
    );
  }

  Future<void> _deleteCourse(BuildContext context, String courseId) async {
    try {
      await FirebaseFirestore.instance.collection('cursos').doc(courseId).delete();

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Curso eliminado exitosamente')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el curso: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error desconocido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generar Cursos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('cursos').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar los cursos'));
            }
            if (snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No hay cursos disponibles'));
            }

            final courses = snapshot.data!.docs;

            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                var course = courses[index];
                var courseData = course.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      title: Text(courseData['nombre_curso'] ?? 'Nombre no disponible'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID Curso: ${courseData['id_curso'] ?? 'No disponible'}'),
                          Text('Paralelo: ${courseData['paralelo'] ?? 'No disponible'}'),
                          Text('Tutor: ${courseData['tutor'] ?? 'No disponible'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(CupertinoIcons.pencil),
                            onPressed: () {
                              showAddSubjectSheet(context, course.id);
                            },
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.trash),
                            onPressed: () {
                              _deleteCourse(context, course.id);
                            },
                          ),
                          IconButton(
                            icon: Icon(CupertinoIcons.person_add),
                            onPressed: () {
                              showEnrollmentSheet(context, course.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddCourseSheet(context); // Llamada para mostrar el modal de creación de curso
        },
        child: Icon(CupertinoIcons.add),
      ),
    );
  }
}
