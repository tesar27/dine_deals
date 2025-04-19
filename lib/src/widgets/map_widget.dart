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
    if (widget.chosenCity != oldWidget.chosenCity &&
        widget.chosenCity != 'Choose your city') {
      _centerOnChosenCity();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
              _mapController.camera.center, _mapController.camera.zoom);
        }
      });
    }
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
              _mapController.camera.center, _mapController.camera.zoom);
          if (widget.chosenCity != 'Choose your city') {
            _centerOnChosenCity();
          }
        }
      });
    }
  }

  void _centerOnChosenCity() async {
    if (widget.chosenCity == 'Choose your city') return;
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
    final restaurantsAsync = widget.restaurants != null
        ? AsyncData<List<Map<String, dynamic>>>(widget.restaurants!)
        : ref.watch(restaurantsNotifierProvider);

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
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(zurichLat, zurichLng),
                      initialZoom: _currentZoom,
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
                        markers: restaurants.map((restaurant) {
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
                          final position = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.high,
                            ),
                          );
                          setState(() {
                            _userLocation =
                                LatLng(position.latitude, position.longitude);
                            _showUserLocation = true;
                          });
                          _mapController.move(_userLocation!, 15.0);
                        } catch (e) {
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
