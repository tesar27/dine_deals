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

  const MapWidget({
    super.key,
    this.onMarkerTapped,
    required this.chosenCity,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  // final MapController _mapController = MapController();
  // Add these state variables at the start of your _MapWidgetState class
  LatLng? _userLocation;
  bool _showUserLocation = false;
  // Default Zurich coordinates
  static const double zurichLat = 47.3769;
  static const double zurichLng = 8.5417;

  final _mapController = MapController(); // Create local instance

  // Default zoom level
  double _currentZoom = 13.0;
  bool _isInitialLoad = true;

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the chosen city changes, update the map center
    if (widget.chosenCity != oldWidget.chosenCity &&
        widget.chosenCity != 'Choose your city') {
      _centerOnChosenCity();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When the widget is first built, try to center on the chosen city
    if (_isInitialLoad && widget.chosenCity != 'Choose your city') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnChosenCity();
      });
      _isInitialLoad = false;
    }
  }

  void _centerOnChosenCity() async {
    if (widget.chosenCity == 'Choose your city') return;
    final citiesAsync = ref.read(citiesNotifierProvider);

    citiesAsync.whenData((cities) {
      // Find the chosen city in the list
      final chosenCityData = cities.firstWhere(
        (city) => city['name'] == widget.chosenCity,
        orElse: () =>
            {'name': widget.chosenCity, 'latitude': null, 'longitude': null},
      );

      // Check if we have coordinates for the chosen city
      if (chosenCityData['latitude'] != null &&
          chosenCityData['longitude'] != null) {
        final lat = double.parse(chosenCityData['latitude'].toString());
        final lng = double.parse(chosenCityData['longitude'].toString());
        _mapController.move(LatLng(lat, lng), _currentZoom);
      } else {
        // If city doesn't have coordinates, try to filter restaurants by city name
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

  @override
  Widget build(BuildContext context) {
    // Watch the restaurants provider
    final restaurantsAsync = ref.watch(restaurantsNotifierProvider);

    // Filter restaurants by chosen city if a city is selected
    final filteredRestaurantsAsync = restaurantsAsync.whenData((restaurants) {
      if (widget.chosenCity == 'Choose your city') {
        return restaurants;
      } else {
        return restaurants
            .where((restaurant) =>
                restaurant['address'] != null &&
                restaurant['address'].toString().contains(widget.chosenCity))
            .toList();
      }
    });

    return filteredRestaurantsAsync.when(
      data: (restaurants) {
        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Wrap FlutterMap with a Stack
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(zurichLat, zurichLng),
                      initialZoom: _currentZoom,
                    ),
                    children: [
                      TileLayer(
                        // CARTO Voyager No Labels - designed for minimal place markers
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const [
                          'a',
                          'b',
                          'c',
                          'd'
                        ], // Standard CARTO subdomains
                        // It's polite and often required to identify your app
                        // IMPORTANT: Replace with your actual package name
                        userAgentPackageName: 'com.dinedeals.app',
                        // tileProvider: CachedTileProvider(), // Optional: Enables caching tiles locally
                        retinaMode:
                            MediaQuery.of(context).devicePixelRatio > 1.0,
                      ),
                      // Add this CircleLayer for the user's location
                      if (_showUserLocation && _userLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _userLocation!,
                              radius: 10,
                              color: Colors.blue
                                  .withOpacity(0.7), // Inner blue circle
                              borderColor: Colors.white,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: false,
                            ),
                            CircleMarker(
                              point: _userLocation!,
                              radius: 30,
                              color: Colors.blue
                                  .withOpacity(0.2), // Outer blue circle
                              useRadiusInMeter: false,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: restaurants.map((restaurant) {
                          // Extract coordinates from restaurant data
                          final double lat = restaurant['latitude'] != null
                              ? double.parse(restaurant['latitude'].toString())
                              : zurichLat;

                          final double lng = restaurant['longitude'] != null
                              ? double.parse(restaurant['longitude'].toString())
                              : zurichLng;

                          final String name =
                              restaurant['name'] ?? 'Unnamed Restaurant';
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
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // --- Attribution Layer (Very Important!) ---
                      // You MUST attribute the map data source (OSM) and the tile provider (CARTO)
                      const RichAttributionWidget(
                        alignment: AttributionAlignment
                            .bottomLeft, // Position at the bottom left
                        // popupInitialDisplayDuration: Duration(seconds: 5),
                        animationConfig: ScaleRAWA(), // Optional nice animation
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            // Optional: Make OSM link clickable (requires url_launcher package)
                            // onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                          ),
                          TextSourceAttribution(
                            'CARTO',
                            // Optional: Make CARTO link clickable (requires url_launcher package)
                            // onTap: () => launchUrl(Uri.parse('https://carto.com/attributions')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Add the Locate Me button
                  Positioned(
                    right: 16,
                    bottom: 20, // Position above the controls container
                    child: FloatingActionButton(
                      heroTag: 'locate_me',
                      mini: true,
                      shape: const CircleBorder(),
                      backgroundColor: Colors.blue,
                      elevation: 0,
                      onPressed: () async {
                        try {
                          // Get location
                          final position = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.high,
                            ),
                          );
                          // Update state to show user location
                          setState(() {
                            _userLocation =
                                LatLng(position.latitude, position.longitude);
                            _showUserLocation = true;
                          });
                          // Move map to user location
                          _mapController.move(_userLocation!, 15.0);
                        } catch (e) {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Transform.rotate(
                        angle: 45 * 3.14159 / 180,
                        child:
                            const Icon(Icons.navigation, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Center button changes based on chosen city
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
