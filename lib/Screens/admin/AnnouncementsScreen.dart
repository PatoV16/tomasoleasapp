import 'dart:typed_data'; // Necesario para manejar los bytes
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io'; // Para trabajar con File (solo en plataformas móviles)

class AnnouncementsScreen extends StatefulWidget {
  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _selectedFile; // Solo para móviles
  Uint8List? _selectedFileBytes; // Para web, almacenar los bytes
  String _fileName = "Ningún archivo seleccionado";

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (result.files.single.bytes != null) {
          _selectedFileBytes = result.files.single.bytes;
        } else {
          _selectedFile = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _uploadFile() async {
    if ((_selectedFile == null && _selectedFileBytes == null) || 
        _titleController.text.isEmpty || 
        _subtitleController.text.isEmpty || 
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos y selecciona un archivo.'))
      );
      return;
    }

    try {
      String fileName = _fileName;
      Reference storageReference = FirebaseStorage.instance.ref().child("comunicados/$fileName");

      UploadTask uploadTask;
      if (_selectedFileBytes != null) {
        uploadTask = storageReference.putData(_selectedFileBytes!);
      } else {
        uploadTask = storageReference.putFile(_selectedFile!);
      }

      await uploadTask;
      String downloadUrl = await storageReference.getDownloadURL();

      await FirebaseFirestore.instance.collection('comunicados').add({
        'titulo': _titleController.text,
        'subtitulo': _subtitleController.text,
        'descripcion': _descriptionController.text,
        'file_url': downloadUrl,
        'file_name': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivo y datos subidos con éxito')));
      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
        _fileName = "Ningún archivo seleccionado";
        _titleController.clear();
        _subtitleController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir el archivo')));
    }
  }

  Future<void> _deleteAnnouncement(String docId) async {
    await FirebaseFirestore.instance.collection('comunicados').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comunicado eliminado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text("Comunicados"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoTextField(
              controller: _titleController,
              placeholder: "Título",
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
            SizedBox(height: 10),
            CupertinoTextField(
              controller: _subtitleController,
              placeholder: "Subtítulo",
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
            SizedBox(height: 10),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: "Descripción",
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            Text("Archivo seleccionado: $_fileName"),
            SizedBox(height: 10),
            CupertinoButton.filled(
              onPressed: _pickFile,
              child: Text("Seleccionar archivo"),
            ),
            SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _uploadFile,
              child: Text("Subir archivo"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('comunicados').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No hay comunicados disponibles"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(doc['titulo']),
                        subtitle: Text(doc['subtitulo']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Función para editar el comunicado
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAnnouncement(doc.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
