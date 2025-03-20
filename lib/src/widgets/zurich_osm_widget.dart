import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ZurichOSMWidget extends StatefulWidget {
  final Function(String)? onMarkerTapped;

  const ZurichOSMWidget({
    super.key, 
    this.onMarkerTapped,
  });

  @override
  State<ZurichOSMWidget> createState() => _ZurichOSMWidgetState();
}

class _ZurichOSMWidgetState extends State<ZurichOSMWidget> {
  final MapController _mapController = MapController();
  
  // Zurich coordinates
  static const double zurichLat = 47.3769;
  static const double zurichLng = 8.5417;
  
  // Default zoom level
  double _currentZoom = 13.0;
  
  // List of Zurich restaurants
  final List<Map<String, dynamic>> _restaurants = [
    {
      'name': 'Hiltl',
      'lat': 47.3728,
      'lng': 8.5386,
      'description': 'World\'s oldest vegetarian restaurant'
    },
    {
      'name': 'Zeughauskeller',
      'lat': 47.3699,
      'lng': 8.5391,
      'description': 'Historic Swiss restaurant with traditional food'
    },
    {
      'name': 'Kronenhalle',
      'lat': 47.3668,
      'lng': 8.5468,
      'description': 'Upscale dining with art-covered walls'
    },
    {
      'name': 'Sternen Grill',
      'lat': 47.3666,
      'lng': 8.5457,
      'description': 'Famous for its bratwurst'
    },
    {
      'name': 'Café Sprüngli',
      'lat': 47.3697,
      'lng': 8.5389,
      'description': 'Luxury confectionery and chocolate'
    },
  ];

  void _centerOnZurich() {
    _mapController.move(const LatLng(zurichLat, zurichLng), 13);
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(zurichLat, zurichLng),
              initialZoom: 13,
              onTap: (_, __) {
                // Close any open popups when tapping on the map
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dine_deals',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: _restaurants.map((restaurant) {
                  return Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(restaurant['lat'], restaurant['lng']),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onMarkerTapped != null) {
                          widget.onMarkerTapped!(restaurant['name']);
                        }
                        
                        // Show a popup with restaurant info
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(restaurant['name']),
                            content: Text(restaurant['description']),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              restaurant['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _centerOnZurich,
                child: const Text('Center on Zurich'),
              ),
              ElevatedButton(
                onPressed: _zoomIn,
                child: const Text('Zoom In'),
              ),
              ElevatedButton(
                onPressed: _zoomOut,
                child: const Text('Zoom Out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
