import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';
import 'package:dine_deals/src/providers/cities_provider.dart';

class MapWidget extends ConsumerStatefulWidget {
  final Function(String)? onMarkerTapped;
  final String chosenCity;
  final bool isVisible;
  final List<Map<String, dynamic>>? restaurants; // Add restaurants parameter

  const MapWidget({
    super.key,
    this.onMarkerTapped,
    required this.chosenCity,
    required this.isVisible,
    this.restaurants, // Add this parameter
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  LatLng? _userLocation;
  bool _showUserLocation = false;
  static const double zurichLat = 47.3769;
  static const double zurichLng = 8.5417;

  final _mapController = MapController();

  double _currentZoom = 13.0;
  static const double _cityClusterZoomThreshold =
      10.0; // Threshold for showing city clusters vs individual restaurants

  @override
  void initState() {
    super.initState();
    if (widget.isVisible && widget.chosenCity != 'Choose your city') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _centerOnChosenCity();
        }
      });
    }
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.chosenCity != oldWidget.chosenCity || 
        widget.isVisible != oldWidget.isVisible) &&
        widget.chosenCity != 'Choose your city') {
      // Use a slight delay to ensure the map is properly initialized
      Future.delayed(Duration.zero, () {
        if (mounted) {
          _centerOnChosenCity();
        }
      });
    }
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.chosenCity != 'Choose your city') {
            _centerOnChosenCity();
          } else {
            // If no city is chosen, ensure the map reflects the current state
            _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom);
          }
        }
      });
    }
  }

  void _centerOnChosenCity() async {
    if (widget.chosenCity == 'Choose your city') return;
    
    print("Centering on city: ${widget.chosenCity}");
    
    final citiesAsync = ref.read(citiesNotifierProvider);

    citiesAsync.whenData((cities) {
      final chosenCityData = cities.firstWhere(
        (city) => city['name'] == widget.chosenCity,
        orElse: () =>
            {'name': widget.chosenCity, 'latitude': null, 'longitude': null},
      );

      if (chosenCityData['latitude'] != null &&
          chosenCityData['longitude'] != null) {
        final lat = double.parse(chosenCityData['latitude'].toString());
        final lng = double.parse(chosenCityData['longitude'].toString());
        
        print("Moving map to coordinates: $lat, $lng");
        
        _mapController.move(LatLng(lat, lng), _currentZoom);
      } else {
        final restaurantsAsync = ref.read(restaurantsNotifierProvider);
        restaurantsAsync.whenData((restaurants) {
          final cityRestaurants = restaurants
              .where((r) =>
                  r['address'] != null &&
                  r['address'].toString().contains(widget.chosenCity))
              .toList();

          if (cityRestaurants.isNotEmpty &&
              cityRestaurants[0]['latitude'] != null &&
              cityRestaurants[0]['longitude'] != null) {
            final lat = double.parse(cityRestaurants[0]['latitude'].toString());
            final lng =
                double.parse(cityRestaurants[0]['longitude'].toString());
                
            print("Moving map to restaurant coordinates: $lat, $lng");
            
            _mapController.move(LatLng(lat, lng), _currentZoom);
          }
        });
      }
    });
  }

  void _centerOnDefault() {
    _mapController.move(const LatLng(zurichLat, zurichLng), _currentZoom);
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

  // Helper method to group restaurants by city and create city clusters
  List<Marker> _createCityClusters(List<Map<String, dynamic>> restaurants,
      List<Map<String, dynamic>> cities) {
    // Group restaurants by city
    final Map<String, List<Map<String, dynamic>>> restaurantsByCity = {};

    for (var restaurant in restaurants) {
      final address = restaurant['address'] as String?;
      if (address == null) continue;

      // Find which city this restaurant belongs to
      String? cityName;
      for (var city in cities) {
        final name = city['name'] as String?;
        if (name != null &&
            address.toLowerCase().contains(name.toLowerCase())) {
          cityName = name;
          break;
        }
      }

      if (cityName != null) {
        if (!restaurantsByCity.containsKey(cityName)) {
          restaurantsByCity[cityName] = [];
        }
        restaurantsByCity[cityName]!.add(restaurant);
      }
    }

    // Create a marker for each city that has restaurants
    final List<Marker> cityMarkers = [];

    for (var city in cities) {
      final cityName = city['name'] as String?;
      if (cityName == null || !restaurantsByCity.containsKey(cityName)) {
        continue;
      }

      final restaurants = restaurantsByCity[cityName]!;
      if (restaurants.isEmpty) continue;

      // Get city coordinates
      final cityLat = double.tryParse(city['latitude']?.toString() ?? '') ?? 0;
      final cityLng = double.tryParse(city['longitude']?.toString() ?? '') ?? 0;

      // Create a marker for this city with a count of restaurants
      cityMarkers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(cityLat, cityLng),
          child: GestureDetector(
            onTap: () {
              // Zoom in when a city cluster is tapped
              _mapController.move(
                  LatLng(cityLat, cityLng), _cityClusterZoomThreshold + 1);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    restaurants.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cityName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(125, 255, 255, 255),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return cityMarkers;
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = widget.restaurants != null
        ? AsyncData<List<Map<String, dynamic>>>(widget.restaurants!)
        : ref.watch(restaurantsNotifierProvider);

    final citiesAsync = ref.watch(citiesNotifierProvider);

    return restaurantsAsync.when(
      data: (restaurants) {
        // Filter restaurants by chosen city if specified
        final filteredRestaurants = widget.chosenCity == 'Choose your city'
            ? restaurants
            : restaurants
                .where((restaurant) =>
                    restaurant['address'] != null &&
                    restaurant['address']
                        .toString()
                        .contains(widget.chosenCity))
                .toList();

        return citiesAsync.when(
          data: (cities) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(zurichLat, zurichLng),
                          initialZoom: _currentZoom,
                          onMapEvent: (event) {
                            // Update current zoom level when map changes
                            if (event.source == MapEventSource.mapController ||
                                event.source ==
                                    MapEventSource.flingAnimationController ||
                                event.source ==
                                    MapEventSource
                                        .doubleTapZoomAnimationController) {
                              setState(() {
                                _currentZoom = event.camera.zoom;
                              });
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.dinedeals.app',
                            retinaMode:
                                MediaQuery.of(context).devicePixelRatio > 1.0,
                          ),
                          if (_showUserLocation && _userLocation != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _userLocation!,
                                  radius: 10,
                                  color: Colors.blue.withOpacity(0.7),
                                  borderColor: Colors.white,
                                  borderStrokeWidth: 2,
                                  useRadiusInMeter: false,
                                ),
                                CircleMarker(
                                  point: _userLocation!,
                                  radius: 30,
                                  color: Colors.blue.withOpacity(0.2),
                                  useRadiusInMeter: false,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: _currentZoom < _cityClusterZoomThreshold
                                ? _createCityClusters(
                                    filteredRestaurants, cities)
                                : filteredRestaurants.map((restaurant) {
                                    final double lat = restaurant['latitude'] !=
                                            null
                                        ? double.parse(
                                            restaurant['latitude'].toString())
                                        : zurichLat;

                                    final double lng =
                                        restaurant['longitude'] != null
                                            ? double.parse(
                                                restaurant['longitude']
                                                    .toString())
                                            : zurichLng;

                                    final String name = restaurant['name'] ??
                                        'Unnamed Restaurant';
                                    final String address =
                                        restaurant['address'] ?? 'No address';

                                    return Marker(
                                      width: 120.0,
                                      height: 60.0,
                                      point: LatLng(lat, lng),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (widget.onMarkerTapped != null) {
                                            widget.onMarkerTapped!(name);
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(name),
                                              content: Text(address),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.fastfood,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                          ),
                          const RichAttributionWidget(
                            alignment: AttributionAlignment.bottomLeft,
                            animationConfig: ScaleRAWA(),
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                              ),
                              TextSourceAttribution(
                                'CARTO',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: FloatingActionButton(
                          heroTag: 'locate_me',
                          mini: true,
                          shape: const CircleBorder(),
                          backgroundColor: Colors.blue,
                          elevation: 0,
                          onPressed: () async {
                            try {
                              final position =
                                  await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.high,
                                ),
                              );
                              final userLatLng = LatLng(position.latitude, position.longitude);
                              setState(() {
                                _userLocation = userLatLng;
                                _showUserLocation = true;
                                // Update _currentZoom state when moving map
                                _currentZoom = 15.0;
                              });
                              // Move map after state is updated
                              _mapController.move(userLatLng, 15.0);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error getting location: $e'), // Improved error message
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Transform.rotate(
                            angle: 45 * 3.14159 / 180,
                            child: const Icon(Icons.navigation,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      // Add zoom level indicator for debugging
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.grey[100],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.chosenCity != 'Choose your city'
                            ? _centerOnChosenCity
                            : _centerOnDefault,
                        icon: const Icon(Icons.location_searching),
                        label: Text(widget.chosenCity != 'Choose your city'
                            ? 'Center on ${widget.chosenCity}'
                            : 'Default View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoom_in',
                            onPressed: _zoomIn,
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out',
                            onPressed: _zoomOut,
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading cities data: $error'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading restaurants: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(restaurantsNotifierProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
