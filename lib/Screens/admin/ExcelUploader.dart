import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ExcelUploader {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> previewData = [];
  late ScaffoldMessengerState scaffoldMessenger;

  int _getIntValue(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  void didChangeDependencies(BuildContext context) {
    scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> openFileExplorer(BuildContext context, String courseId) async {
    didChangeDependencies(context);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.isNotEmpty) {
      Uint8List? fileBytes = result.files.single.bytes;
      if (fileBytes != null) {
        var excel = Excel.decodeBytes(fileBytes);
        previewData.clear();

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            if (row.length >= 7) {
              String cedula = row[0]?.value?.toString() ?? '';
              int edad = _getIntValue(row[1]?.value);
              String etnia = row[2]?.value?.toString() ?? '';
              DateTime fechaNacimiento = DateTime.tryParse(row[3]?.value?.toString() ?? '') ?? DateTime.now();
              String nombre = row[4]?.value?.toString() ?? '';
              String representante = row[5]?.value?.toString() ?? '';
              String telefonoRepresentante = row[6]?.value?.toString() ?? '';

              previewData.add({
                'cedula': cedula,
                'edad': edad,
                'etnia': etnia,
                'fecha_nacimiento': fechaNacimiento,
                'nombre': nombre,
                'representante': representante,
                'telefono_representante': telefonoRepresentante,
              });
            }
          }
        }
        _showPreviewDialog(context, courseId);
      }
    } else {
      _showMessage('No se seleccionó ningún archivo.');
    }
  }

  Future<void> uploadData(
    String cedula,
    int edad,
    String etnia,
    DateTime fechaNacimiento,
    String nombre,
    String representante,
    String telefonoRepresentante,
    String courseId,
  ) async {
    await firestore.collection('estudiantes').doc(cedula).set({
      'edad': edad,
      'etnia': etnia,
      'fecha_nacimiento': Timestamp.fromDate(fechaNacimiento),
      'nombre': nombre,
      'representante': representante,
      'telefono_representante': telefonoRepresentante,
      'curso_id': courseId, // Guardar el ID del curso
      'role': 'estudiante'
    });
  }

  void _showPreviewDialog(BuildContext context, String courseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Previsualización de Datos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: previewData.length,
              itemBuilder: (context, index) {
                final item = previewData[index];
                return ListTile(
                  title: Text(item['nombre']),
                  subtitle: Text(
                      "Cédula: ${item['cedula']}, Edad: ${item['edad']}, Etnia: ${item['etnia']}, \n"
                      "Fecha de Nacimiento: ${item['fecha_nacimiento']}, Representante: ${item['representante']}, \n"
                      "Teléfono Representante: ${item['telefono_representante']}"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
              },
              child: Text('Subir a Firebase'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadAllData(String courseId) async {
    await Future.wait(previewData.map((item) => uploadData(
          item['cedula'],
          item['edad'],
          item['etnia'],
          item['fecha_nacimiento'],
          item['nombre'],
          item['representante'],
          item['telefono_representante'],
          courseId,
        )));
    _showMessage('Datos subidos correctamente.');
  }

  void _showMessage(String message) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

