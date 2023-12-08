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
  Map<String, dynamic>? _foundEvent;

  Future<void> _searchEventById(String eventId) async {
    try {
      // ID del usuario actual
      String userId = FirebaseAuth.instance.currentUser!.uid;

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
                  SnackBar(
                    content: const Text("No se puede agregar este evento a las invitaciones porque es tuyo"),
                    duration: const Duration(seconds: 2),
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
                };
              });
              return;
            }
          }
        }
      }

      // No se encontraron coincidencias, muestra un Snackbar y borra los datos anteriores
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No hay coincidencias"),
          duration: const Duration(seconds: 2),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Evento por ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _eventIdController,
                decoration: InputDecoration(
                  labelText: 'ID del Evento',
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
                child: const Text('Buscar'),
              ),
              const SizedBox(height: 16),
              if (_foundEvent != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descripción: ${_foundEvent!['descripcion']}'),
                    Text('Tipo de Evento: ${_foundEvent!['tipoEvento']}'),
                    Text('Creado por: ${_foundEvent!['creadorNombre']} ${_foundEvent!['creadorApellido']}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
