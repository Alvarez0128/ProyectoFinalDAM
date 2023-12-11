import 'pantallaInicio.dart';
import 'pantallaRegistro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppFinal extends StatefulWidget {
  const AppFinal({Key? key}) : super(key: key);

  @override
  State<AppFinal> createState() => _AppFinalState();
}

class _AppFinalState extends State<AppFinal> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();

  @override
  void initState() {
    super.initState();
    // Inicializa Firebase
    Firebase.initializeApp();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Inicia sesión con Firebase Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _usernameController.text,
          password: _passwordController.text,
        );

        // Consulta Firestore para obtener nombre y apellido
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('correo', isEqualTo: _usernameController.text)
            .get()
            .then((querySnapshot) => querySnapshot.docs.first);

        String nombre = userSnapshot['nombre'];
        String apellido = userSnapshot['apellido'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(child: Text('Bienvenid@, $nombre', style: const TextStyle(color: Colors.blue,fontSize: 18)),),
            backgroundColor: Colors.white,
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 40),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              //side: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        );

        // Navegar a la pantalla de inicio y forzar la reconstrucción
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaInicio(nombreUsuario: '$nombre',apellidoUsuario: '$apellido',),
          ),
        );

        print('Inicio de sesión exitoso');
        limpiarCampos();
      } catch (e) {
        // Si hay un error, muestra un SnackBar con el mensaje de error
        String errorMessage = 'Error de inicio de sesión';
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            errorMessage = 'Correo no encontrado';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Contraseña incorrecta';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Correo inválido';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.red)),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(color: Colors.red),
            ),
          ),
        );
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
  void limpiarCampos(){
    setState(() {
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // Deja el AppBar vacío
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60.0),
                  TextFormField(
                    focusNode: _focusNode1,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Por favor, ingrese su correo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    focusNode: _focusNode2,
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Por favor, ingrese su contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: (){_handleLogin();FocusScope.of(context).unfocus();},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      limpiarCampos();
                      // Navegar a la pantalla de registro
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const pantallaRegistro()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 33.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: const Text('Registrarse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}
