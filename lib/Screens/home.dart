import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin/loginAdmin.dart';
import 'login.dart';
import 'registerScreen.dart';
import 'students/StudentLoginScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> announcements = [];

  // Obtiene los comunicados desde Firestore
  Future<void> fetchAnnouncements() async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection('comunicados')
        .orderBy('timestamp', descending: true)
        .get();
        
    final List<Map<String, dynamic>> fetchedAnnouncements = result.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    setState(() {
      announcements = fetchedAnnouncements;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  // Abre el archivo en el navegador para descargarlo
  Future<void> downloadFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'No se pudo abrir el enlace $url';
    }
  }

  final List<Map<String, IconData>> services = [
    {"Administrador": CupertinoIcons.person},
    {"Profesor": CupertinoIcons.person_2_alt},
    {"Estudiante": CupertinoIcons.person_2_square_stack},
    
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Inicio'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Comunicados
              Text('Comunicados', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
              SizedBox(height: 10),
              Container(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      color: CupertinoColors.systemGrey6,
                      child: Container(
                        width: 200,
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              announcement['titulo'] ?? '',
                              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 5),
                            Text(
                              announcement['subtitulo'] ?? '',
                              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10),
                            CupertinoButton(
                              child: Text("Ver archivo"),
                              onPressed: () {
                                final fileUrl = announcement['file_url'];
                                if (fileUrl != null) {
                                  downloadFile(fileUrl);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('URL de archivo no disponible'))
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Sección de Servicios
              Text('Servicios', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
              SizedBox(height: 10),
              GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index].keys.first;
                  final icon = services[index][service]!;

                  return GestureDetector(
                    onTap: () async {
                      if (service == "Profesor") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen(), maintainState: false),
                        );
                      } else if (service == "Administrador") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminLoginScreen(), maintainState: false),
                        );
                      } else if (service == "Estudiante") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentLoginScreen(), maintainState: false),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 40, color: CupertinoColors.activeBlue),
                          SizedBox(height: 10),
                          Text(service, style: CupertinoTheme.of(context).textTheme.textStyle, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
