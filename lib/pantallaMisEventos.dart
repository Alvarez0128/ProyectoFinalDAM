import 'package:dam_proyectofinal/pantallaDetalleMisEventos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyEventsScreen extends StatefulWidget {
  final String nombreUsuario;
  final String apellidoUsuario;
  final String idUsuario;
  MyEventsScreen({required this.nombreUsuario,required this.apellidoUsuario,required this.idUsuario});
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
    _loadAllEventPhotos();
  }

  Future<void> _showDeleteConfirmationDialog(String eventId, String eventDescription) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar evento'),
          content: Text('¿Estás seguro de que deseas eliminar el evento "$eventDescription"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteEvent(eventId);
                Navigator.of(context).pop();
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteEvent(String eventId, String eventDescription) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el evento "$eventDescription"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
                _deleteEvent(eventId);
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      // Elimina el evento de Firestore
      try {
        // Obtén una referencia al documento del usuario
        DocumentReference userDocRef = _firestore.collection('usuarios').doc(_user.uid);

        // Obtiene los datos actuales del documento del usuario
        DocumentSnapshot userDocSnapshot = await userDocRef.get();
        Map<String, dynamic> userData = userDocSnapshot.data() as Map<String, dynamic>;

        // Obtiene la lista de eventos del usuario
        List<dynamic> eventos = List.from(userData['eventos']);

        // Encuentra y elimina el subdocumento específico
        eventos.removeWhere((evento) => evento['id'] == eventId);

        // Actualiza el documento del usuario con la lista de eventos modificada
        await userDocRef.update({'eventos': eventos});
      } catch (e) {
        print('Error al eliminar el evento: $e');
      }

      // Elimina las fotos asociadas al evento de Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('event_photos/${_user.uid}/$eventId'); // Cambiar a la nueva ubicación
      await storageRef.listAll().then((result) {
        result.items.forEach((fileRef) async {
          await fileRef.delete();
        });
      });

      // Elimina las fotos asociadas al evento de Firestore
      await _firestore
          .collection('event_photos')  // Cambiar a la nueva colección
          .doc(eventId)
          .collection('photos')
          .get()
          .then((snapshot) {
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      // Elimina las invitaciones de los usuarios que tengan el ID de evento
      await _firestore.collection('usuarios').get().then((userSnapshot) {
        userSnapshot.docs.forEach((userDoc) async {
          List<dynamic> invitaciones = List.from(userDoc['invitaciones']);
          invitaciones.removeWhere((invitacion) => invitacion['id'] == eventId);

          await _firestore.collection('usuarios').doc(userDoc.id).update({'invitaciones': invitaciones});
        });
      });

      // Recarga la lista de eventos después de eliminar
      _loadAllEventPhotos();
    } catch (e) {
      print('Error al eliminar el evento: $e');
    }
  }


  Future<void> _loadAllEventPhotos() async {
    try {
      List<String> allUrls = [];

      // Obtén todos los eventos del usuario
      List<Evento> userEvents = await _getUserEvents();

      // Carga las fotos de todos los eventos
      for (var event in userEvents) {
        QuerySnapshot photoSnapshot = await _firestore
            .collection('event_photos')  // Cambiar a la colección de fotos del evento
            .doc(event.id)
            .collection('photos')
            .get();

        List<String> eventUrls = photoSnapshot.docs
            .map((doc) => doc['photo_url'] as String)
            .toList();

        allUrls.addAll(eventUrls);
      }

      setState(() {
        // Genera una lista de índices aleatorios
        List<int> randomIndices =
        List<int>.generate(allUrls.length, (index) => index)..shuffle();

        // Usa los índices aleatorios para ordenar las fotos
        _photoUrls = randomIndices.map((index) => allUrls[index]).toList();
      });
    } catch (e) {
      print('Error al cargar las fotos de todos los eventos: $e');
    }
  }


  Future<List<Evento>> _getUserEvents() async {
    try {
      // Obtén el ID del usuario actual
      String userId = _user.uid;

      // Consulta Firestore para obtener la lista de eventos del usuario
      var userDoc = await _firestore.collection('usuarios').doc(userId).get();
      var eventos = userDoc['eventos'];

      // Mapea los eventos para obtener las descripciones e IDs
      List<Evento> events = eventos.map<Evento>((evento) {
        return Evento(
          id: evento['id'].toString(),
          descripcion: evento['descripcion'].toString(),
        );
      }).toList();

      return events;
    } catch (e) {
      print('Error al obtener eventos: $e');
      return [];
    }
  }
  Future<String?> _loadEventFirstPhotoUrl(String eventId) async {
    try {
      QuerySnapshot photoSnapshot = await _firestore
          .collection('event_photos')  // Cambiar a la colección de fotos del evento
          .doc(eventId)
          .collection('photos')
          .get();

      if (photoSnapshot.docs.isNotEmpty) {
        // Devuelve la URL de la primera imagen del evento
        return photoSnapshot.docs.first['photo_url'] as String?;
      } else {
        // Si no hay fotos, devuelve null
        return null;
      }
    } catch (e) {
      print('Error al cargar la primera foto del evento: $e');
      return null;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return text.substring(0, maxLength) + "...";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              " Mis Eventos",
              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 24),
            ),
          ),
          FutureBuilder<List<Evento>>(
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
                      SizedBox(
                        height: 10,
                      ),
                      Icon(
                        Icons.photo_library_rounded,
                        color: Colors.grey,
                        size: 50,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Sin eventos registrados",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                );
              } else {
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          _loadAllEventPhotos();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyEventsDetail(
                                descripcion: snapshot.data![index].descripcion,
                                idEvento: snapshot.data![index].id,
                                nombre: widget.nombreUsuario,
                                apellido: widget.apellidoUsuario,
                              ),
                            ),
                          );

                        },
                        onLongPress: () {
                          _showDeleteConfirmationDialog(snapshot.data![index].id, snapshot.data![index].descripcion);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(3, 5, 3, 5),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                            color: const Color.fromRGBO(162, 204, 242, 0.7),
                            child: Container(
                              width: 130,
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20,),
                                  // CircleAvatar con foto del evento
                                  FutureBuilder<String?>(
                                    future: _loadEventFirstPhotoUrl(snapshot.data![index].id),
                                    builder: (context, snapshotUrl) {
                                      if (snapshotUrl.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      } else if (snapshotUrl.hasError || snapshotUrl.data == null) {
                                        // Manejar el caso de error o si no hay URL disponible
                                        return const CircleAvatar(
                                          radius: 50,
                                          child: Icon(Icons.no_photography_outlined, size: 55, color: Colors.white,),
                                        );
                                      } else {
                                        // Mostrar la imagen del CircleAvatar si la URL está disponible
                                        return CircleAvatar(
                                          radius: 50,
                                          backgroundImage: NetworkImage(snapshotUrl.data!),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10,),
                                  // Texto de descripción del evento
                                  Flexible(
                                    child: Text(
                                      _truncateText(snapshot.data![index].descripcion, 12), // Cambia 20 al número de caracteres deseados
                                      style: const TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                ],
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
          const SizedBox(
            height: 10,
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              " Fotos Destacadas",
              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 24),
            ),
          ),
          Expanded(
            child: _photoUrls.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(80, 0, 80, 0),
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.photo_size_select_large_rounded,color: Colors.grey,size: 35,),
                          Text(
                            "Aquí aparecerán las fotos destacadas de tus eventos",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey,fontSize: 16),
                          ),
                      ],
                    )))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: _photoUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Image.network(
                          _photoUrls[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Evento {
  final String id;
  final String descripcion;

  Evento({required this.id, required this.descripcion});
}
