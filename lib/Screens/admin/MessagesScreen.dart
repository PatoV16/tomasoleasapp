import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference messagesCollection = FirebaseFirestore.instance.collection('mensajes');

  // Función para enviar mensaje
  Future<void> _sendMessage(String senderName) async {
    if (_messageController.text.isNotEmpty) {
      try {
        await messagesCollection.add({
          'mensaje': _messageController.text,
          'nombre': senderName,
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
        middle: Text('Mensajes'),
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
          var timestamp = messageData['timestamp'] as Timestamp?;

          String timeString = timestamp != null
              ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
              : 'Hora no disponible';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: CupertinoListTile(
              title: Text(senderName, style: TextStyle(fontSize: 16)),
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
                    onPressed: () {
                      // Asigna el nombre del remitente (puedes obtenerlo de la autenticación o de otra fuente)
                      String senderName = "Admin"; // Reemplaza con el nombre real del usuario
                      _sendMessage(senderName);
                    },
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
