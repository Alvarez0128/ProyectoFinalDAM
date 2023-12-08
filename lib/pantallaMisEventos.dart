import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyEventsScreen extends StatefulWidget {
  @override
  _MyEventsScreenState createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
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
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              snapshot.data![index],
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
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
