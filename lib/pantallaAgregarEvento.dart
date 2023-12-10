import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchEventScreen extends StatefulWidget {
  @override
  _SearchEventScreenState createState() => _SearchEventScreenState();
}

class _SearchEventScreenState extends State<SearchEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _eventIdController = TextEditingController();
  String userId = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? _foundEvent;

  Future<void> _searchEventById(String eventId) async {
    try {
      // ID del usuario actual
      //String userId = FirebaseAuth.instance.currentUser!.uid;

      // Consulta Firestore para buscar el evento por ID en todos los documentos de usuarios
      QuerySnapshot userSnapshots =
      await FirebaseFirestore.instance.collection('usuarios').get();

      for (QueryDocumentSnapshot userSnapshot in userSnapshots.docs) {
        List<dynamic>? events = userSnapshot['eventos'];

        if (events != null) {
          // Busca el evento en el arreglo de eventos del usuario actual
          for (var event in events) {
            if (event['id'] == eventId) {
              if (userSnapshot.id == userId) {
                // El evento pertenece al usuario actual
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No se puede agregar este evento a las invitaciones porque es tuyo"),
                    duration: Duration(seconds: 2),
                  ),
                );
                setState(() {
                  _foundEvent = null;
                });
                return;
              }

              // Se encontró el evento, ahora obtenemos el nombre y apellido del creador
              DocumentSnapshot creatorSnapshot =
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userSnapshot.id)
                  .get();

              setState(() {
                _foundEvent = {
                  'descripcion': event['descripcion'],
                  'tipoEvento': event['tipoEvento'],
                  'creadorNombre': creatorSnapshot['nombre'],
                  'creadorApellido': creatorSnapshot['apellido'],
                  'subirFotosInvitados':event['subirFotosInvitados']
                };
              });
              return;
            }
          }
        }
      }

      // No se encontraron coincidencias, muestra un Snackbar y borra los datos anteriores
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay coincidencias"),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _foundEvent = null;
      });
    } catch (e) {
      // Maneja cualquier error que pueda ocurrir durante la búsqueda
      print("Error al buscar el evento: $e");
    }
  }

  Future<bool> _invitationExists(String invitationId) async {
    // ID del usuario actual
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Consulta Firestore para obtener las invitaciones del usuario actual
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('usuarios').doc(userId).get();
    List<dynamic>? invitations = userSnapshot['invitaciones'];

    if (invitations != null) {
      // Verifica si la invitación ya existe
      return invitations.any((invitation) => invitation['id'] == invitationId);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference userReference = FirebaseFirestore.instance.collection('usuarios').doc(userId);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Agregar evento',style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 20, 50, 0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _eventIdController,
                  decoration: InputDecoration(
                    labelText: 'ID del Evento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ingrese el ID del evento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Realiza la búsqueda cuando se presiona el botón
                      _searchEventById(_eventIdController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text('Buscar'),
                ),
                const SizedBox(height: 45),
                if (_foundEvent != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 2, // Puedes ajustar el valor según tus preferencias
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descripción: ${_foundEvent!['descripcion']}', style: const TextStyle(fontSize: 17)),
                          Text('Tipo de Evento: ${_foundEvent!['tipoEvento']}', style: const TextStyle(fontSize: 17)),
                          Text('Creado por: ${_foundEvent!['creadorNombre']} ${_foundEvent!['creadorApellido']}', style: const TextStyle(fontSize: 17)),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () async {

                                  // Verifica si la invitación ya existe antes de agregarla
                                  bool invitationExists = await _invitationExists(_eventIdController.text);

                                  if (invitationExists) {
                                    // Muestra un mensaje si la invitación ya existe
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("La invitación ya existe", style: const TextStyle(color: Colors.red)),
                                        backgroundColor: Colors.white,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                    );
                                  } else {
                                    await userReference.update({
                                      'invitaciones': FieldValue.arrayUnion([
                                        {
                                          'id': _eventIdController.text,
                                          'descripcion': _foundEvent!['descripcion'],
                                          'tipoEvento': _foundEvent!['tipoEvento'],
                                          'creadorNombre': _foundEvent!['creadorNombre'],
                                          'creadorApellido': _foundEvent!['creadorApellido'],
                                          'subirFotosInvitados':_foundEvent!['subirFotosInvitados']
                                        },
                                      ]),
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Evento agregado a las invitaciones", style: const TextStyle(color: Colors.green)),
                                        backgroundColor: Colors.white,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          side: const BorderSide(color: Colors.green),
                                        ),
                                      ),
                                    );

                                    setState(() {
                                      _foundEvent = null;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                                child: const Text('Agregar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      )
    );
  }
}
