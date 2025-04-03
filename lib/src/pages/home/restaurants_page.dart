import 'package:dine_deals/src/widgets/map_screen.dart';
import 'package:flutter/material.dart';

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('This is the restaurans page'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        child: const Icon(Icons.map),
      ),
    );
  }
}
