// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Necesitas agregar esta dependencia
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicia la carga del enlace del PDF
    _fetchPdfUrl();
  }

  // Función para obtener el enlace del PDF desde Firestore
  Future<void> _fetchPdfUrl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('horarios')
          .doc('horario_institucion') // ID del documento con el enlace PDF
          .get();

      if (doc.exists) {
        final pdfUrl = doc.get('pdf_url'); // Campo que almacena el enlace del PDF
        if (pdfUrl != null) {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('No se encontró el documento con el enlace del PDF.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error al obtener el enlace del PDF: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Función para abrir el enlace en el navegador
  Future<void> _openPdfUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url); // Abre el enlace en el navegador
      } else {
        throw 'No se puede abrir el enlace';
      }
    } catch (e) {
      print('Error al abrir el enlace del PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el enlace')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Horario Institucional')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 100,
                    color: Colors.red,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Aquí deberías obtener el enlace del PDF desde Firestore
                      final doc = await FirebaseFirestore.instance
                          .collection('horarios')
                          .doc('horario_institucion')
                          .get();
                      final pdfUrl = doc.get('pdf_url');
                      if (pdfUrl != null) {
                        await _openPdfUrl(pdfUrl); // Abre el enlace del PDF
                      }
                    },
                    child: Text('Abrir PDF en el navegador'),
                  ),
                ],
              ),
            ),
    );
  }
}
