import 'package:flutter/material.dart';

class MyEventsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simulando eventos creados por el usuario
    List<String> userEvents = ['Viaje a la playa', 'Boda de Ana y Juan', 'Cumpleaños de Pedro','Viaje a la playa', 'Boda de Ana y Juan', 'Cumpleaños de Pedro'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Eventos'),
      ),
      body: Column(
        children: [
          Container(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userEvents.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    width: 100, // Tamaño fijo del contenedor
                    padding: const EdgeInsets.all(8), // Padding añadido
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blue,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter, // Posicionar en la parte inferior verticalmente y centrado horizontalmente
                      child: Text(
                        userEvents[index],
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 6, // Número de fotos aleatorias
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    color: Colors.grey[300],
                    // Simulación de fotos aleatorias de cualquier evento
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
}
