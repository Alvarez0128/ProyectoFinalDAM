import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InvitationDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventDescription;
  final bool allowGuestPhotos;

  InvitationDetailScreen({
    required this.eventId,
    required this.eventDescription,
    required this.allowGuestPhotos,
  });

  @override
  _InvitationDetailScreenState createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late User _user;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _photos = [];
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      QuerySnapshot photoSnapshot = await _firestore
          .collection('photos')
          .doc(_user.uid)
          .collection('user_photos')
          .doc(widget.eventId)
          .collection('event_photos')
          .get();

      List<String> urls =
      photoSnapshot.docs.map((doc) => doc['photo_url'] as String).toList();

      setState(() {
        _photos = urls;
      });
    } catch (e) {
      print('Error al cargar las fotos: $e');
    }
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
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = _storage
        .ref()
        .child('photos')
        .child(_user.uid)
        .child(widget.eventId)
        .child(fileName);

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() async {
      String imageUrl = await storageReference.getDownloadURL();

      await _firestore
          .collection('photos')
          .doc(_user.uid)
          .collection('user_photos')
          .doc(widget.eventId)
          .collection('event_photos')
          .add({'photo_url': imageUrl});

      await _loadPhotos();
    });
  }

  Future<void> _confirmDeletePhoto(int index) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Foto'),
          content: const Text('¿Estás seguro de que deseas eliminar esta foto?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _deletePhoto(index);
    }
  }

  Future<void> _deletePhoto(int index) async {
    try {
      DocumentSnapshot photoSnapshot = await _firestore
          .collection('photos')
          .doc(_user.uid)
          .collection('user_photos')
          .doc(widget.eventId)
          .collection('event_photos')
          .where('photo_url', isEqualTo: _photos[index])
          .get()
          .then((querySnapshot) => querySnapshot.docs.first);

      await photoSnapshot.reference.delete();
      await _loadPhotos();
    } catch (e) {
      print('Error al eliminar la foto: $e');
    }
  }

  Widget _buildEventTypeItem(String type) {
    return ListTile(
      title: Text(type),
      onTap: () {
        Navigator.pop(context, type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventDescription),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onLongPress: () {
                    _confirmDeletePhoto(index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Image.network(
                      _photos[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.allowGuestPhotos
          ? FloatingActionButton(
        onPressed: () async {
          await _pickImage();
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
