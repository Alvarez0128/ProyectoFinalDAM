import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyectofinal/pantallaDetalleInvitaciones.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InvitationsScreen extends StatefulWidget {
  @override
  _InvitationsScreenState createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deleteInvitation(String invitationId) async {
    try {
      // Obtén una referencia al documento del usuario
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);

      // Obtiene los datos actuales del documento del usuario
      DocumentSnapshot userDocSnapshot = await userDocRef.get();
      Map<String, dynamic> userData = userDocSnapshot.data() as Map<String, dynamic>;

      // Obtiene la lista de invitaciones del usuario
      List<dynamic> invitaciones = List.from(userData['invitaciones']);

      // Encuentra y elimina la invitación específica
      invitaciones.removeWhere((invitacion) => invitacion['id'] == invitationId);

      // Actualiza el documento del usuario con la lista de invitaciones modificada
      await userDocRef.update({'invitaciones': invitaciones});
    } catch (e) {
      print('Error al eliminar la invitación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    Timestamp timestamp;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Invitaciones',style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          List<dynamic>? invitations = snapshot.data!['invitaciones'];

          if (invitations == null || invitations.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(60, 0, 60, 0),
              child: Center(
                child: Text("Agrega un nuevo código de evento y empieza a compartir",textAlign: TextAlign.center,style: TextStyle(color: Colors.grey,fontSize: 16),),
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: invitations.map<Widget>((invitation) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InvitationDetailScreen(
                            eventId: invitation['id'],
                            eventDescription: invitation['descripcion'],
                            allowGuestPhotos: true,
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      // Muestra un cuadro de diálogo de confirmación para eliminar la invitación
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Eliminar invitación'),
                            content: Text('¿Estás seguro de que deseas eliminar esta invitación?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _deleteInvitation(invitation['id']);
                                  Navigator.of(context).pop();
                                },
                                child: Text('Eliminar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      color: Colors.blue,
                      margin: const EdgeInsets.fromLTRB(10,20,10,20),
                      elevation: 10,
                      child: Container(
                        width: screenWidth*.7,
                        height: screenHeight*.65,
                        padding: const EdgeInsets.all(16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    invitation['descripcion'],
                                    style: const TextStyle(fontSize: 24.0,color: Colors.white,fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10,),
                                  Text(
                                    "Tipo: ${invitation['tipoEvento']}",
                                    style: const TextStyle(fontSize: 21.0,color: Colors.white),
                                  ),
                                  const SizedBox(height: 10,),
                                  const Text(
                                    "Creado por:",
                                    style: TextStyle(fontSize: 21.0,color: Colors.white),
                                  ),
                                  Text(
                                    "${invitation['creadorNombre']} ${invitation['creadorApellido']}",
                                    style: const TextStyle(fontSize: 21.0,color: Colors.white),
                                  ),
                                ],
                              )
                          ),
                        )
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
