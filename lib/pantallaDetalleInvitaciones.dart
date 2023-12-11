import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

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
          .collection('event_photos')
          .doc(widget.eventId)
          .collection('photos')
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
        .child('event_photos')
        .child(widget.eventId)
        .child(fileName);

    UploadTask uploadTask = storageReference.putFile(file);

    await uploadTask.whenComplete(() async {
      String imageUrl = await storageReference.getDownloadURL();

      await _firestore
          .collection('event_photos')
          .doc(widget.eventId)
          .collection('photos')
          .add({'photo_url': imageUrl});

      await _loadPhotos();
    });
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
            child: _photos.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo,
                          color: Colors.grey,
                          size: 55,
                        ),
                        Text(
                          'Sin fotos',
                          style: TextStyle(fontSize: 18.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Image.network(
                          _photos[index],
                          fit: BoxFit.cover,
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
