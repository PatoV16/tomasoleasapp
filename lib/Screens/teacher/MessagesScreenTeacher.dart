import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessagesScreenTeacher extends StatefulWidget {
  @override
  _MessagesScreenTeacherState createState() => _MessagesScreenTeacherState();
}

class _MessagesScreenTeacherState extends State<MessagesScreenTeacher> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference messagesCollection = FirebaseFirestore.instance.collection('mensajes');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? senderName;
  String? title;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

Future<void> _fetchTeacherData() async {
  final user = _auth.currentUser;
  if (user != null) {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('profesores')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final teacherDoc = querySnapshot.docs.first;
      setState(() {
        senderName = teacherDoc['nombre'];
        title = teacherDoc['titulo'];
      });
    }
  }
}

  // Función para enviar mensaje
  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && senderName != null && title != null) {
      try {
        await messagesCollection.add({
          'mensaje': _messageController.text,
          'nombre': senderName,
          'tituloP': title,
          'timestamp': Timestamp.now(),
        });
        _messageController.clear(); // Limpia el campo de entrada
      } catch (e) {
        print("Error al enviar el mensaje: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Mensajes del Profesor'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // StreamBuilder para mostrar los mensajes en tiempo real
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesCollection.orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar los mensajes'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CupertinoActivityIndicator());
                  }

                  final messages = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var messageData = messages[index].data() as Map<String, dynamic>;
                      var messageText = messageData['mensaje'] ?? 'Mensaje no disponible';
                      var senderName = messageData['nombre'] ?? 'Remitente desconocido';
                      var senderTitle = messageData['tituloP'] ?? 'Título no disponible';
                      var timestamp = messageData['timestamp'] as Timestamp?;

                      String timeString = timestamp != null
                          ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                          : 'Hora no disponible';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                        child: CupertinoListTile(
                          title: Text('$senderName, $senderTitle', style: TextStyle(fontSize: 16)),
                          subtitle: Text(messageText, style: TextStyle(color: CupertinoColors.systemGrey)),
                          trailing: Text(timeString, style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Escribe un mensaje...',
                    ),
                  ),
                  CupertinoButton(
                    onPressed: _sendMessage,
                    child: Icon(CupertinoIcons.paperplane_fill),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
