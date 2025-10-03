import 'package:flutter/material.dart';

class MapBottomControls extends StatelessWidget {
  final VoidCallback onAllCities;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapBottomControls({
    super.key,
    required this.onAllCities,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: onAllCities,
            icon: const Icon(Icons.public),
            label: const Text('All Cities'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          Row(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: onZoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: onZoomOut,
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
