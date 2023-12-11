import 'dart:io';
import 'package:dam_proyectofinal/pantallaActualizarEvento.dart';
import 'package:dam_proyectofinal/pantallaInicio.dart';
import 'package:dam_proyectofinal/pantallaMisEventos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MyEventsDetail extends StatefulWidget {
  final String descripcion;
  final String idEvento;
  final String nombre;
  final String apellido;

  MyEventsDetail({required this.descripcion, required this.idEvento,required this.nombre,required this.apellido});

  @override
  _MyEventsDetailState createState() => _MyEventsDetailState();
}

class _MyEventsDetailState extends State<MyEventsDetail> {
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
      // Obtener URLs de fotos desde Firestore
      QuerySnapshot photoSnapshot = await _firestore
          .collection('event_photos')  // Cambiar a la colección de fotos del evento
          .doc(widget.idEvento)
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
    try {
      // Subir imagen a Firebase Storage
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage
          .ref()
          .child('event_photos')  // Cambiar a la carpeta de fotos del evento
          .child(widget.idEvento)
          .child(fileName);

      UploadTask uploadTask = storageReference.putFile(file);

      await uploadTask.whenComplete(() async {
        // Obtener URL de la imagen y guardarla en Firestore
        String imageUrl = await storageReference.getDownloadURL();

        await _firestore
            .collection('event_photos')  // Cambiar a la colección de fotos del evento
            .doc(widget.idEvento)
            .collection('photos')
            .add({'photo_url': imageUrl});

        // Actualizar la lista de fotos
        await _loadPhotos();
      });
    } catch (e) {
      print('Error al subir la imagen: $e');
    }
  }


  Future<void> _deletePhoto(int index) async {
    try {
      String photoUrl = _photos[index];

      // Obtener la referencia de la imagen en Firebase Storage
      Reference storageReference = _storage.refFromURL(photoUrl);

      // Eliminar la imagen de Firebase Storage
      await storageReference.delete();

      // Eliminar la foto de Firestore
      await _firestore
          .collection('event_photos')  // Cambiar a la colección de fotos del evento
          .doc(widget.idEvento)
          .collection('photos')
          .where('photo_url', isEqualTo: photoUrl)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) async {
          await doc.reference.delete();
        });
      });

      // Actualizar la lista de fotos
      await _loadPhotos();
    } catch (e) {
      print('Error al eliminar la foto: $e');
    }
  }


  Future<void> _navigateToUpdateEventScreen(Map<String, dynamic>? event) async {
    // Navegar a la pantalla de actualización del evento con los datos actuales
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateEventScreen(event: event),
      ),
    );

    // Actualizar la lista de fotos después de la actualización (puedes agregar más lógica aquí según sea necesario)
    await _loadPhotos();
  }

  Future<void> showEventInfoDialog(String userId, String eventId) async {
    try {
      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).get();

      if (userSnapshot.exists) {
        List<dynamic> eventos = userSnapshot['eventos'];
        Map<String, dynamic>? selectedEvent;

        for (var evento in eventos) {
          if (evento['id'] == eventId) {
            selectedEvent = evento;
            break;
          }
        }

        if (selectedEvent != null) {
          // Verificar nulidad antes de formatear las fechas
          String formattedStartDate =
          selectedEvent['fechaInicio']?.toDate() != null
              ? DateFormat('dd MMM yyyy')
              .format(selectedEvent['fechaInicio'].toDate())
              : 'Fecha no disponible';

          String formattedEndDate =
          selectedEvent['fechaFinal']?.toDate() != null
              ? DateFormat('dd MMM yyyy')
              .format(selectedEvent['fechaFinal'].toDate())
              : 'Fecha no disponible';

          String permiso =
          selectedEvent['subirFotosInvitados'] ? "Sí" : "No";

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(selectedEvent?['descripcion']),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ID del Evento: ${selectedEvent?['id']}'),
                    Text('Fecha de Inicio: $formattedStartDate'),
                    Text('Fecha de Finalización: $formattedEndDate'),
                    Text('Tipo de Evento: ${selectedEvent?['tipoEvento']}'),
                    Text('Permitir a invitados subir fotos: $permiso'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: selectedEvent?['id']));
                    },
                    child: Text('Copiar ID'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Cerrar el diálogo actual
                      Navigator.of(context).pop();

                      // Abrir la pantalla de actualización del evento
                      await _navigateToUpdateEventScreen(selectedEvent);
                    },
                    child: Text('Editar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cerrar'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print('Error al obtener la información del evento: $e');
    }
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
                Navigator.of(context).pop(false); // No confirmar
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar
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
    return WillPopScope(
        onWillPop: () async {
          // Navigator.pushReplacement para reemplazar la pantalla actual
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PantallaInicio(nombreUsuario: widget.nombre,apellidoUsuario: widget.apellido,)), // Reemplaza con la pantalla anterior
          );

          return false; // Devolver false para evitar el pop normal del AppBar
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.descripcion),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () {
                  showEventInfoDialog(_user.uid,widget.idEvento);
                },
              ),
            ],
          ),
          body: _photos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.fromLTRB(85, 0, 85, 0),
                  child: Center(
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
                        SizedBox(
                          height: 100,
                        ),
                        Text(
                          'Pulsa el botón de + para empezar a subir tus fotos',
                          style: TextStyle(fontSize: 18.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
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
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await _pickImage();
            },
            child: const Icon(Icons.add),
          ),
        ));
  }
}



