import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PantallaEdicionUsuario extends StatefulWidget {
  final String userId;

  const PantallaEdicionUsuario({Key? key, required this.userId}) : super(key: key);

  @override
  _PantallaEdicionUsuarioState createState() => _PantallaEdicionUsuarioState();
}

class _PantallaEdicionUsuarioState extends State<PantallaEdicionUsuario> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late User _user;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  bool _isEditMode = false;
  String _photoURL="";

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _photoURL = '';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(widget.userId).get();

      setState(() {
        _nombreController.text = userDoc['nombre'];
        _apellidoController.text = userDoc['apellido'];
        _correoController.text = userDoc['correo'];
        _photoURL = userDoc['photoURL'];
      });
    } catch (e) {
      print('Error al cargar los datos del usuario: $e');
    }
  }

  Future<void> _updateUserData() async {
    try {
      await _firestore.collection('usuarios').doc(widget.userId).update({
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'correo': _correoController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos actualizados correctamente',style: TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al actualizar los datos del usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al actualizar los datos',style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final ImagePicker _picker = ImagePicker();

    try {
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);
        String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = _storage.ref().child('profile_photos/${_user.uid}/$fileName');

        await storageRef.putFile(file);

        String downloadURL = await storageRef.getDownloadURL();

        await _firestore.collection('usuarios').doc(widget.userId).update({'photoURL': downloadURL});

        setState(() {
          _photoURL = downloadURL;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto de perfil actualizada correctamente'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error al subir la foto de perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al subir la foto de perfil',style: TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        // Subir la imagen a Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_photos/${_user.uid}');
        UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));

        // Esperar a que se complete la subida
        await uploadTask.whenComplete(() async {
          // Obtener la URL de la imagen subida
          String downloadURL = await storageRef.getDownloadURL();

          // Actualizar la URL de la foto en la interfaz y en Firebase Firestore
          setState(() {
            _photoURL = downloadURL;
          });

          // Actualizar el atributo 'photoURL' del usuario en Firestore
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(_user.uid)
              .update({'photoURL': downloadURL});
        });
      } catch (e) {
        print('Error al subir la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });

              if (_isEditMode) {
                _loadUserData();
              } else {
                // Guardar los datos actualizados
                _updateUserData();
              }
            },
            icon: Icon(_isEditMode ? Icons.save : Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (_isEditMode) {
                  _pickAndUploadImage();
                }
              },
              child: CircleAvatar(
                radius: 90,
                backgroundImage: _isEditMode ? null : NetworkImage(_photoURL),
                child: _isEditMode
                    ? Icon(
                  Icons.camera_alt,
                  size: 40,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              enabled: _isEditMode,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apellidoController,
              enabled: _isEditMode,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _correoController,
              enabled: _isEditMode,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
          ],
        ),
      ),
    );
  }
}
