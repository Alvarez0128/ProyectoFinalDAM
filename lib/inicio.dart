import 'package:dam_proyectofinal/PRUEBA.dart';
import 'package:flutter/material.dart';

class PantallaInicio extends StatefulWidget {
  final String nombreUsuario;

  const PantallaInicio({Key? key, required this.nombreUsuario}) : super(key: key);

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.blue
                ),
                children: [
                  const TextSpan(
                    text: '   Bienvenido, ',
                  ),
                  TextSpan(
                    text: widget.nombreUsuario,
                    style: const TextStyle(
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
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16.0),
              Icon(Icons.camera_alt,color: Colors.grey,size: 80,),
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                  onPressed: (){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoGalleryScreen(),
                      ),
                    );
                  },
                  child: Text("GALERÍA"))
            ],
          ),
        ),
      ),
    );
  }
}
