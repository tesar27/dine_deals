import 'package:flutter/material.dart';
import '../../widgets/zurich_osm_widget.dart';

class ZurichMapPage extends StatelessWidget {
  const ZurichMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zurich Restaurants'),
      ),
      body: ZurichOSMWidget(
        onMarkerTapped: (restaurantName) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: $restaurantName'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
