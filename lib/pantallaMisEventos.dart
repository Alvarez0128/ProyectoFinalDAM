import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyEventsScreen extends StatefulWidget {
  @override
  _MyEventsScreenState createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User _user;
  late List<String> _photoUrls;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;

    _photoUrls = [];
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    // Obtener URLs de fotos desde Firestore
    QuerySnapshot photoSnapshot =
    await _firestore.collection('photos').doc(_user.uid).collection('user_photos').get();

    List<String> urls =
    photoSnapshot.docs.map((doc) => doc['photo_url'] as String).toList();

    setState(() {
      _photoUrls = urls;
    });
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.first.path!);
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    // Subir imagen a Firebase Storage
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
    _storage.ref().child('photos').child(_user.uid).child(fileName);

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() async {
      // Obtener URL de la imagen y guardarla en Firestore
      String imageUrl = await storageReference.getDownloadURL();

      await _firestore
          .collection('photos')
          .doc(_user.uid)
          .collection('user_photos')
          .add({'photo_url': imageUrl});

      // Actualizar la lista de fotos
      await _loadPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          FutureBuilder<List<String>>(
            future: _getUserEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Icon(Icons.photo_library_rounded,color: Colors.grey,size: 50,),
                      SizedBox(height: 20,),
                      Text("Sin eventos registrados",style: TextStyle(color: Colors.grey),),
                      SizedBox(height: 20,),
                    ],
                  ),
                );
              } else {
                return Container(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(3,5,3,5),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          color: Colors.blue,
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                snapshot.data![index],
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Text(
                        'Foto ${index + 1}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getUserEvents() async {
    try {
      // Obtén el ID del usuario actual
      String userId = _user.uid;

      // Consulta Firestore para obtener la lista de eventos del usuario
      var userDoc = await _firestore.collection('usuarios').doc(userId).get();
      var eventos = userDoc['eventos'];

      // Mapea los eventos para obtener las descripciones
      //List<String> descriptions = eventos.map<String>((evento) => evento['descripcion']).toList();
      List<String> descriptions = eventos.map<String>((evento) => evento['descripcion'].toString()).toList();


      return descriptions;
    } catch (e) {
      print('Error al obtener eventos: $e');
      return [];
    }
  }
}
