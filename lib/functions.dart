import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';


void showEditStudentSheet(BuildContext context, String studentId, Map<String, dynamic> studentData) {
  final TextEditingController nombreController = TextEditingController(text: studentData['nombre']);
  final TextEditingController edadController = TextEditingController(text: studentData['edad']?.toString());
  final TextEditingController etniaController = TextEditingController(text: studentData['etnia']);
  final TextEditingController representanteController = TextEditingController(text: studentData['representante']);
  final TextEditingController telefonoController = TextEditingController(text: studentData['telefono_representante']);

  showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      return CupertinoActionSheet(
        title: Text('Editar Estudiante'),
        message: Column(
          children: [
            CupertinoTextField(controller: nombreController, placeholder: 'Nombre del Estudiante'),
            CupertinoTextField(controller: edadController, placeholder: 'Edad', keyboardType: TextInputType.number),
            CupertinoTextField(controller: etniaController, placeholder: 'Etnia'),
            CupertinoTextField(controller: representanteController, placeholder: 'Representante'),
            CupertinoTextField(controller: telefonoController, placeholder: 'Teléfono del Representante', keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('estudiantes').doc(studentId).update({
                  'nombre': nombreController.text,
                  'edad': int.tryParse(edadController.text) ?? 0,
                  'etnia': etniaController.text,
                  'representante': representanteController.text,
                  'telefono_representante': telefonoController.text,
                });
                Navigator.pop(context); // Cierra el ActionSheet

                // Usa el contexto del Scaffold adecuado para mostrar el SnackBar
                ScaffoldMessenger.of(Scaffold.of(context) as BuildContext).showSnackBar(
                  SnackBar(
                    content: Text('Estudiante actualizado exitosamente'),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(Scaffold.of(context) as BuildContext).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo actualizar al estudiante'),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              }
            },
            child: Text('Guardar cambios'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('estudiantes').doc(studentId).delete();
                Navigator.pop(context); // Cierra el ActionSheet

                ScaffoldMessenger.of(Scaffold.of(context) as BuildContext).showSnackBar(
                  SnackBar(
                    content: Text('Estudiante eliminado'),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(Scaffold.of(context) as BuildContext).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo eliminar al estudiante'),
                    backgroundColor: Colors.black,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              }
            },
            child: Text('Eliminar estudiante'),
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



  // Función para mostrar el popup de edición
  void showEditStudentPopup(BuildContext context, String studentId) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text('Editar Estudiante'),
          message: Text('Modifica los datos del estudiante.'),
          actions: [
            CupertinoActionSheetAction(
              child: Text('Editar Datos'),
              onPressed: () {
                //
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.pop(context); // Cierra el popup
            },
          ),
        );
      },
    );
  }


