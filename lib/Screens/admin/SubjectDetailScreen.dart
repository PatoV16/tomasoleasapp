import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectId;

  SubjectDetailsScreen({required this.subjectId});

  @override
  _SubjectDetailsScreenState createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController codigoController = TextEditingController();
  String? selectedProfesorId;
  List<Map<String, String>> profesores = [];

  @override
  void initState() {
    super.initState();
    _fetchProfesores();
    _fetchSubjectDetails();
  }

  Future<void> _fetchProfesores() async {
    final snapshot = await FirebaseFirestore.instance.collection('profesores').get();
    setState(() {
      profesores = snapshot.docs.map((doc) => {
        'id': doc.id,
        'nombre': doc['nombre']?.toString() ?? '',
      }).toList();
    });
  }

  Future<void> _fetchSubjectDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('materias').doc(widget.subjectId).get();
      if (doc.exists) {
        final data = doc.data()!;
        nombreController.text = data['nombre'] ?? '';
        codigoController.text = data['codigo'] ?? '';
        selectedProfesorId = data['profesorId'];
        setState(() {});
      } else {
        throw Exception('Materia no encontrada');
      }
    } catch (e) {
      _showErrorDialog('Error al cargar los detalles de la materia: ${e.toString()}');
    }
  }

  void _updateSubjectData() async {
    final String nombre = nombreController.text;
    final String codigo = codigoController.text;

    if (nombre.isEmpty || codigo.isEmpty || selectedProfesorId == null) {
      _showErrorDialog('Por favor completa todos los campos');
      return;
    }

    String? profesorNombre = profesores.firstWhere(
      (prof) => prof['id'] == selectedProfesorId,
      orElse: () => {'nombre': 'Desconocido'}
    )['nombre'];

    try {
      await FirebaseFirestore.instance.collection('materias').doc(widget.subjectId).update({
        'nombre': nombre,
        'codigo': codigo,
        'profesor': profesorNombre,
        'profesorId': selectedProfesorId,
      });

      if (!mounted) return;

      _showSuccessDialog('Datos de la materia actualizados');
    } catch (e) {
      _showErrorDialog('Error al actualizar la materia: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Éxito'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Cierra el diálogo y vuelve a la pantalla anterior
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Detalles de la Materia'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Guardar', style: TextStyle(color: CupertinoColors.activeBlue)),
          onPressed: _updateSubjectData,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              CupertinoTextField(
                controller: nombreController,
                placeholder: 'Nombre de la Materia',
              ),
              SizedBox(height: 16),
              CupertinoTextField(
                controller: codigoController,
                placeholder: 'Código de la Materia',
              ),
              SizedBox(height: 16),
              Text('Profesor', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
              GestureDetector(
                onTap: () => _showProfesorPicker(context),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    selectedProfesorId != null
                        ? profesores.firstWhere((prof) => prof['id'] == selectedProfesorId)['nombre'] ?? 'Seleccionar profesor'
                        : 'Seleccionar profesor',
                    style: TextStyle(fontSize: 18, color: CupertinoColors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfesorPicker(BuildContext context) {
    int initialIndex = profesores.indexWhere((prof) => prof['id'] == selectedProfesorId);
    if (initialIndex == -1) {
      initialIndex = 0;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text('Selecciona un Profesor', style: TextStyle(fontSize: 18)),
        actions: [
          Container(
            height: 200,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: initialIndex),
              onSelectedItemChanged: (int index) {
                setState(() {
                  selectedProfesorId = profesores[index]['id'];
                });
              },
              children: profesores
                  .map((prof) => Center(
                        child: Text(
                          prof['nombre'] ?? '',
                          style: TextStyle(fontSize: 16),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar', style: TextStyle(color: CupertinoColors.destructiveRed)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
