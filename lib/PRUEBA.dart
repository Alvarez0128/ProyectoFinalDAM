import 'dart:io';

import 'package:dam_proyectofinal/pantallaCrearEvento.dart';
import 'package:dam_proyectofinal/pantallaMisEventos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PhotoGalleryScreen extends StatefulWidget {
  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User _user;
  late List<String> _photoUrls;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _photoUrls = [];

    // Cargar fotos existentes al iniciar
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
      ),
      body: dinamico(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(5,10,5,10),
        child: BottomNavigationBar(
          selectedFontSize: 13,
          unselectedFontSize: 13,
          iconSize: 30,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Mis Eventos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail),
              label: 'Invitaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Crear Evento',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }

  Widget dinamico(){
    switch(_selectedIndex){
      case 0: {
        return MyEventsScreen();
      } //case 0
      case 1: {
        return Center();
      } //Termina caso 1
      case 2: {
        return CreateEventScreen();
      }
      default: {
        return Center();
      }
    }
  }
}
