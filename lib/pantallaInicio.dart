
import 'package:dam_proyectofinal/login.dart';
import 'package:dam_proyectofinal/pantallaInvitaciones.dart';

import 'pantallaAgregarEvento.dart';
import 'pantallaCrearEvento.dart';
import 'pantallaMisEventos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantallaInicio extends StatefulWidget {
  final String nombreUsuario;

  const PantallaInicio({Key? key, required this.nombreUsuario}) : super(key: key);

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late User _user;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  void _handleLogout() async {
    await _auth.signOut();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AppFinal(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                    color: Colors.blue
                ),
                children: [
                  TextSpan(
                    text: '   KCA ',
                    style: TextStyle(fontWeight: FontWeight.w600)
                  ),
                  TextSpan(
                    text: "App",
                    style: TextStyle(
                      color: Color.fromRGBO(66, 66, 66, 1),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(), // Espacio flexible para empujar el CircleAvatar hacia la derecha
            const Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                child: Padding(
                  padding: const EdgeInsets.all(0.0), // Cambiar el tamaño del borde
                  child: CircleAvatar(
                    radius: 19,
                    //backgroundColor: Colors.blueGrey,
                    backgroundImage: AssetImage('assets/perfil.png'),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Cerrar Sesión'),
                ),
              ),
            ],
          ),
        ],
      ),

      body: dinamico(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        child: BottomNavigationBar(
          selectedFontSize: 13,
          unselectedFontSize: 13,
          iconSize: 30,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _selectedIndex == 0
                  ? const Icon(Icons.photo_camera_back_rounded)
                  : const Icon(Icons.photo_camera_back_outlined),
              label: 'Mis Eventos',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? const Icon(Icons.photo_camera_front_rounded)
                  : const Icon(Icons.photo_camera_front_outlined),
              label: 'Invitaciones',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 2
                  ? const Icon(Icons.add_circle_rounded)
                  : const Icon(Icons.add_circle_outline_rounded),
              label: 'Crear Evento',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 3
                  ? const Icon(Icons.add_photo_alternate)
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: 'Agregar Evento',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: const Color.fromRGBO(80, 80,80, 1), // Establecer el color para los ítems no seleccionados
          onTap: _onItemTapped,
          elevation: 0,
        ),
      ),
    );
  }
  Widget dinamico() {
    switch (_selectedIndex) {
      case 0:
        {
          return MyEventsScreen(nombreUsuario: widget.nombreUsuario,idUsuario: _user.uid,);
        } //case 0
      case 1:
        {
          return InvitationsScreen();
        } //Termina caso 1
      case 2:
        {
          return CreateEventScreen();
        }
      case 3:
        {
          return SearchEventScreen();
        }
      default:
        {
          return const Center();
        }
    }
  }
}
