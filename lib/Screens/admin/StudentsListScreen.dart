import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../functions.dart';
class StudentsListScreen extends StatelessWidget {
  final String courseId;

  StudentsListScreen({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Lista de Estudiantes'),
      ),
      child: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('estudiantes')
              .where('curso_id', isEqualTo: courseId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No hay estudiantes en este curso.'),
              );
            }

            var students = snapshot.data!.docs;

            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index].data() as Map<String, dynamic>;
                String studentId = students[index].id;

                // Extraer los campos del estudiante
                String nombre = student['nombre'] ?? 'Sin Nombre';
                String cedula = studentId;
                int edad = student['edad'] ?? 0;
                String etnia = student['etnia'] ?? 'No especificado';
                DateTime fechaNacimiento = (student['fecha_nacimiento'] as Timestamp).toDate();
                String representante = student['representante'] ?? 'No especificado';
                String telefonoRepresentante = student['telefono_representante'] ?? 'No especificado';

                return CupertinoListTile(
                  title: Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Cédula: $cedula", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                      Text("Edad: $edad", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                      Text("Etnia: $etnia", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                      Text("Fecha de Nacimiento: ${fechaNacimiento.toLocal().toString().split(' ')[0]}", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                      Text("Representante: $representante", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                      Text("Teléfono Representante: $telefonoRepresentante", style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(CupertinoIcons.pencil, color: CupertinoColors.activeBlue),
                    onPressed: () {
                      showEditStudentSheet(context, cedula, student);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
