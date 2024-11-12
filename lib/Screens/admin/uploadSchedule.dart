import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class UploadScheduleScreen extends StatefulWidget {
  @override
  _UploadScheduleScreenState createState() => _UploadScheduleScreenState();
}

class _UploadScheduleScreenState extends State<UploadScheduleScreen> {
  bool isUploading = false;
  bool isDeleting = false;
  String? uploadedPdfUrl;

  @override
  void initState() {
    super.initState();
    _fetchPdfUrl(); // Cargar el enlace PDF al iniciar la pantalla
  }

  // Obtener el enlace PDF de Firestore
  Future<void> _fetchPdfUrl() async {
    final doc = await FirebaseFirestore.instance.collection('horarios').doc('horario_institucion').get();
    if (doc.exists) {
      setState(() {
        uploadedPdfUrl = doc['pdf_url'];
      });
    }
  }

  // Función para seleccionar y subir el archivo PDF
  Future<void> _uploadPdf() async {
    setState(() => isUploading = true);

    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result == null) {
        setState(() => isUploading = false);
        return;
      }

      final fileBytes = result.files.single.bytes; // Utilizamos bytes para web
      final fileName = result.files.single.name;

      // Subir archivo a Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('horarios/$fileName');
      final uploadTask = storageRef.putData(fileBytes!); // Usamos putData con los bytes
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar el enlace en Firestore
      await FirebaseFirestore.instance.collection('horarios').doc('horario_institucion').set({'pdf_url': downloadUrl});

      setState(() {
        uploadedPdfUrl = downloadUrl;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivo subido exitosamente')));
    } catch (e) {
      print('Error al subir el PDF: $e');
      setState(() => isUploading = false);
    }
  }

  // Función para eliminar el PDF de Storage y Firestore
  Future<void> _deletePdf() async {
    if (uploadedPdfUrl == null) return;

    setState(() => isDeleting = true);

    try {
      // Eliminar de Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(uploadedPdfUrl!);
      await storageRef.delete();

      // Eliminar enlace de Firestore
      await FirebaseFirestore.instance.collection('horarios').doc('horario_institucion').delete();

      setState(() {
        uploadedPdfUrl = null;
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivo eliminado exitosamente')));
    } catch (e) {
      print('Error al eliminar el PDF: $e');
      setState(() => isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subir y Administrar Horario')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isUploading
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadPdf,
                    icon: Icon(Icons.upload_file),
                    label: Text('Subir PDF de Horario'),
                  ),
            SizedBox(height: 20),
            if (uploadedPdfUrl != null)
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Horario subido'),
                subtitle: Text('Enlace disponible'),
                trailing: isDeleting
                    ? CircularProgressIndicator()
                    : IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: _deletePdf,
                      ),
              )
            else
              Text('No hay horario disponible.'),
          ],
        ),
      ),
    );
  }
}
