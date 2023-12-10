import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedEventType = 'Viaje';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();
  FocusNode _focusNode3 = FocusNode();
  FocusNode _focusNode4 = FocusNode();
  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;

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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Crear Evento',
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
                  focusNode: _focusNode1,
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
                  focusNode: _focusNode2,
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
                    text: '${_startDate.day}-${_startDate.month}-${_startDate.year}',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  focusNode: _focusNode3,
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
                  focusNode: _focusNode4,
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
                    text: '${_endDate.day}-${_endDate.month}-${_endDate.year}',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try{
                        FocusScope.of(context).unfocus();
                        // ID del usuario actual
                        String userId = _user.uid;

                        // Genera un nuevo ID único para el evento
                        String eventId = _firestore.collection('usuarios').doc().id;

                        // Crea un nuevo evento
                        Map<String, dynamic> nuevoEvento = {
                          'id': eventId,
                          'descripcion': _descriptionController.text,
                          'fechaInicio': _startDate,
                          'tipoEvento': _selectedEventType,
                          'fechaFinal': _endDate,
                        };

                        // Agrega el nuevo evento como subdocumento en la colección de eventos del usuario
                        await _firestore.collection('usuarios').doc(userId).update({
                          'eventos': FieldValue.arrayUnion([nuevoEvento]),
                        });

                        // Mostrar cuadro de diálogo para copiar el ID del evento
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Evento creado correctamente'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Ajusta la altura del AlertDialog
                                children: [
                                  const Text('ID del evento:'),
                                  Text(eventId, style: TextStyle(fontWeight: FontWeight.bold),),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => FlutterClipboard.copy(eventId).then((_) => Navigator.of(context).pop()),
                                  child: const Text('Copiar ID'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              titlePadding: const EdgeInsets.all(16),
                            );
                          },
                        );



                        limpiarCampos();
                      }catch(e){
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Ocurrió un error", style: TextStyle(color: Colors.red)),
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
                      // También puedes agregar la lógica para navegar a la pantalla de eventos, etc.
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
                  child: const Text('Crear Evento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void limpiarCampos() {
    setState(() {
      _descriptionController.clear();
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      _selectedEventType = 'Viaje';
    });
  }
}
