import 'package:flutter/material.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedEventType = 'Viaje';

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    ))!;
    if (picked != null && picked != _startDate) {
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
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEventType(BuildContext context) async {
    String? selectedType = await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 200.0,
          child: ListView(
            children: [
              _buildEventTypeItem('Viaje'),
              _buildEventTypeItem('Cumpleaños'),
              _buildEventTypeItem('Boda'),
              _buildEventTypeItem('Quinceañera'),
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
      appBar: AppBar(
        title: Text(
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
                SizedBox(height: 16),
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
                    if (_startDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
                      return 'Seleccione una fecha válida';
                    }
                    return null;
                  },
                  controller: TextEditingController(
                    text: '${_startDate.day}-${_startDate.month}-${_startDate.year}',
                  ),
                ),
                SizedBox(height: 16),
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
                SizedBox(height: 16),
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
                    text: '${_endDate.day}-${_endDate.month}-${_endDate.year}',
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // La validación pasa, puedes continuar con la lógica para almacenar datos en Firestore
                      // Aquí puedes utilizar Firestore para guardar la información del evento
                      // Puedes utilizar los valores de _descriptionController.text, _startDate, _endDate, y _selectedEventType
                    }
                  },
                  child: Text('Crear Evento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
