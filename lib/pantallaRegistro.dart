import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class pantallaRegistro extends StatefulWidget {
  const pantallaRegistro({Key? key}) : super(key: key);

  @override
  State<pantallaRegistro> createState() => _pantallaRegistroState();
}

class _pantallaRegistroState extends State<pantallaRegistro> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleRegistration() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _correoController.text,
          password: _passwordController.text,
        );

        // Crear un arreglo vacío de documentos llamado "invitaciones"
        List<Map<String, dynamic>> invitaciones = [];

        // Guardar información adicional en Firestore con invitaciones vacías
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'nombre': _nombreController.text,
          'apellido': _apellidoController.text,
          'correo': _correoController.text,
          'photoURL':'',
          'invitaciones': invitaciones, // Agregar el arreglo de invitaciones aquí
        });

        // Registro exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text("Registro exitoso", style: TextStyle(color: Colors.green)),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: const BorderSide(color: Colors.green),
            ),
          ),
        );

        // Navegar a otra pantalla después del registro si es necesario
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppFinal()),
        );
      } catch (e) {
        // Manejo de errores durante el registro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error $e", style: const TextStyle(color: Colors.red)),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // Deja el AppBar vacío
          ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 50, 50, 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, ingrese su nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _apellidoController,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, ingrese su apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _correoController,
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
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Repetir Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, ingrese su contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50.0, vertical: 12.0),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
    );
  }
}
