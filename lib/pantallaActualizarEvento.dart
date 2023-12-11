import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyectofinal/pantallaDetalleMisEventos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpdateEventScreen extends StatefulWidget {
  final Map<String, dynamic>? event;

  UpdateEventScreen({required this.event});

  @override
  _UpdateEventScreenState createState() => _UpdateEventScreenState();
}

class _UpdateEventScreenState extends State<UpdateEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _descriptionController =
  TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedEventType = 'Viaje';
  bool _subirFotosInvitados = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;

    // Inicializar los campos con los valores actuales del evento
    _descriptionController.text = widget.event?['descripcion'] ?? '';
    _startDate = widget.event?['fechaInicio'].toDate() ?? DateTime.now();
    _endDate = widget.event?['fechaFinal'].toDate() ?? DateTime.now();
    _selectedEventType = widget.event?['tipoEvento'] ?? 'Viaje';
    _subirFotosInvitados = widget.event?['subirFotosInvitados'] ?? false;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    ))!;
    if (picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    ))!;
    if (picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEventType(BuildContext context) async {
    String? selectedType = await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300.0,
          child: ListView(
            children: [
              _buildEventTypeItem('Viaje'),
              _buildEventTypeItem('Cumpleaños'),
              _buildEventTypeItem('Boda'),
              _buildEventTypeItem('Quinceañera'),
              _buildEventTypeItem('Bautizo'),
              _buildEventTypeItem('Aniversario'),
              _buildEventTypeItem('Posada'),
              _buildEventTypeItem('Baby Shower'),
              _buildEventTypeItem('Despedida de Solterx'),
            ],
          ),
        );
      },
    );
    if (selectedType != null) {
      setState(() {
        _selectedEventType = selectedType;
      });
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
                MyEventsDetail(descripcion: widget.event?['descripcion'],idEvento: widget.event?['id'],nombre: _user.uid,apellido: _user.uid,)), // Reemplaza con la pantalla anterior
      );

      return false; // Devolver false para evitar el pop normal del AppBar
    },
    child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Actualizar Evento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Por favor, ingrese la descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  onTap: () => _selectStartDate(context),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Inicio',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (_startDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      return 'Seleccione una fecha válida';
                    }
                    return null;
                  },
                  controller: TextEditingController(
                    text: DateFormat('dd-MM-yyyy').format(_startDate),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  onTap: () => _selectEventType(context),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Evento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Seleccione un tipo de evento';
                    }
                    return null;
                  },
                  controller: TextEditingController(text: _selectedEventType),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  onTap: () => _selectEndDate(context),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Finalización',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (_endDate.isBefore(_startDate)) {
                      return 'Seleccione una fecha válida';
                    }
                    return null;
                  },
                  controller: TextEditingController(
                    text: DateFormat('dd-MM-yyyy').format(_endDate),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Permitir a invitados subir fotos'),
                  value: _subirFotosInvitados,
                  onChanged: (value) {
                    setState(() {
                      _subirFotosInvitados = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        FocusScope.of(context).unfocus();

                        // Actualizar el evento en la base de datos
                        await _updateEventInDatabase();

                        // Mostrar mensaje de éxito
                        _showUpdateSuccessSnackBar();

                        // Cerrar la pantalla de actualización
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyEventsDetail(
                              descripcion: _descriptionController.text,
                              idEvento: widget.event?['id'],
                              nombre: _user.uid,
                              apellido: _user.uid,
                            ),
                          ),
                        );
                      } catch (e) {
                        // Manejar errores
                        print('Error al actualizar el evento: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50.0, vertical: 12.0),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text('Actualizar Evento'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _updateEventInDatabase() async {
    // Actualizar el evento en el arreglo de eventos del usuario actual
    String userId = _user.uid;
    String eventId = widget.event?['id'] ?? '';

    Map<String, dynamic> updatedEvent = {
      'id': eventId,
      'descripcion': _descriptionController.text,
      'tipoEvento': _selectedEventType,
      'fechaInicio': _startDate,
      'fechaFinal': _endDate,
      'subirFotosInvitados': _subirFotosInvitados,
    };

    await _firestore.collection('usuarios').doc(userId).update({
      'eventos': FieldValue.arrayRemove([widget.event]),
    });

    await _firestore.collection('usuarios').doc(userId).update({
      'eventos': FieldValue.arrayUnion([updatedEvent]),
    });

    // Actualizar el evento en el arreglo de invitaciones de otros usuarios
    QuerySnapshot userSnapshot = await _firestore.collection('usuarios').get();

    for (QueryDocumentSnapshot userDoc in userSnapshot.docs) {
      String otherUserId = userDoc.id;

      if (otherUserId != userId) {
        // Verificar si el evento existe en el arreglo de invitaciones del usuario actual
        List<dynamic>? invitations = userDoc['invitaciones'];
        bool hasInvitation = invitations?.any((invitation) {
          return invitation['id'] == eventId;
        }) ?? false;

        if (hasInvitation) {
          // Obtener la invitación existente
          Map<String, dynamic>? existingInvitation = invitations?.firstWhere(
                (invitation) => invitation['id'] == eventId,
            orElse: () => null,
          );

          // Crear objeto específico para otros usuarios
          Map<String, dynamic> updatedInvitationForOthers = {
            'id': eventId,
            'descripcion': _descriptionController.text,
            'tipoEvento': _selectedEventType,
            'creadorNombre': existingInvitation?['creadorNombre'] ?? '',
            'creadorApellido': existingInvitation?['creadorApellido'] ?? '',
            'subirFotosInvitados': _subirFotosInvitados,
          };

          await _firestore.collection('usuarios').doc(otherUserId).update({
            'invitaciones': invitations?.map((invitation) {
              return (invitation['id'] == eventId)
                  ? updatedInvitationForOthers
                  : invitation;
            }).toList(),
          });
        }
      }
    }
  }

  void _showUpdateSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Evento actualizado correctamente'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
