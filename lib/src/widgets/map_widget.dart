import 'package:dine_deals/src/widgets/map_bottom_controls.dart';
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
  final List<Map<String, dynamic>>? restaurants;

  const MapWidget({
    super.key,
    this.onMarkerTapped,
    required this.chosenCity,
    required this.isVisible,
    this.restaurants,
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
  // Change the threshold from 10.0 to 13.0 to show clusters until more zoomed in
  static const double _cityClusterZoomThreshold = 13.0;

  // Track if all restaurants are loaded
  bool _allRestaurantsLoaded = false;
  List<Map<String, dynamic>> _allRestaurants = [];
  Map<String, int> _restaurantCountByCity = {};

  // Add a flag to track if we're currently filtering restaurants
  bool _isFiltering = false;

  // Add a state variable to track all loaded restaurants (unfiltered)
  List<Map<String, dynamic>> _allLoadedRestaurants = [];

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAllRestaurants(forceRefresh: false);
          if (widget.chosenCity != 'Choose your city') {
            _centerOnChosenCity();

            // If a city is chosen, set zoom to just above threshold to show individual restaurants
            setState(() {
              _currentZoom = _cityClusterZoomThreshold + 0.5;
            });
          } else {
            // If no city chosen, show an overview of all cities
            setState(() {
              _currentZoom = 8.0; // Set a zoom level that shows more area
            });
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only reload if the city changes, not just visibility
    if ((widget.isVisible && !oldWidget.isVisible) ||
        (widget.chosenCity != oldWidget.chosenCity)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 1) reload all restaurants & regroup by city
        _loadAllRestaurants(forceRefresh: false);
        // 2) recenter and bump zoom if a city was chosen
        if (widget.chosenCity != 'Choose your city') {
          _centerOnChosenCity();
          setState(() {
            _currentZoom = _cityClusterZoomThreshold + 0.5;
          });
        }
      });
    }

    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (widget.chosenCity != 'Choose your city') {
            _centerOnChosenCity();
          } else {
            _mapController.move(
                _mapController.camera.center, _mapController.camera.zoom);
          }
        }
      });
    }
  }

  // Modified to use forceRefresh parameter and handle errors better
  Future<void> _loadAllRestaurants({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _allRestaurantsLoaded = false;
        _isFiltering = true;
      });

      try {
        // Step 1: Get cities data first
        final citiesAsync = ref.read(citiesNotifierProvider);
        final cities = await citiesAsync.when(
          data: (data) => Future.value(data),
          loading: () => Future.delayed(
            const Duration(seconds: 1),
            () => throw Exception('Cities still loading'),
          ),
          error: (error, _) => throw Exception('Failed to load cities: $error'),
        );

        // Step 2: Get restaurants data - use the passed forceRefresh parameter
        final restaurantsNotifier =
            ref.read(restaurantsNotifierProvider.notifier);
        final allRestaurantsData = await restaurantsNotifier.fetchRestaurants(
            forceRefresh: forceRefresh);

        if (!mounted) return;

        // Store the complete restaurant list in state
        setState(() {
          _allLoadedRestaurants = allRestaurantsData;
        });

        // Create a normalized map of city names for easier matching
        final Map<String, String> normalizedCityNames = {};
        for (var city in cities) {
          final name = city['name'] as String?;
          if (name != null) {
            normalizedCityNames[name.toLowerCase()] = name;

            // Add shortened versions for better matching
            // e.g. "New York City" -> also match "New York"
            if (name.contains(' ')) {
              final parts = name.split(' ');
              if (parts.length > 1) {
                normalizedCityNames[parts.first.toLowerCase()] = name;
              }
            }
          }
        }

        print("Cities available: ${normalizedCityNames.values.toList()}");

        // Group restaurants by city with improved matching
        final Map<String, List<Map<String, dynamic>>> restaurantsByCity = {};
        final Map<String, int> countByCity = {};

        for (var restaurant in allRestaurantsData) {
          final address = restaurant['address']?.toString().toLowerCase() ?? '';

          // Try to match city by checking if the address contains any known city name
          String? matchedCity;

          // First try exact matches from the cities database
          for (final cityKey in normalizedCityNames.keys) {
            if (address.contains(cityKey)) {
              matchedCity = normalizedCityNames[cityKey];
              break;
            }
          }

          // If no match, try extracting from the address format
          if (matchedCity == null) {
            final extractedCity = _extractCityFromAddress(address);

            // Check if extracted city might match any normalized city
            for (final cityKey in normalizedCityNames.keys) {
              if (cityKey.contains(extractedCity.toLowerCase()) ||
                  extractedCity.toLowerCase().contains(cityKey)) {
                matchedCity = normalizedCityNames[cityKey];
                break;
              }
            }
          }

          // Store the restaurant with its matched city
          if (matchedCity != null) {
            // Initialize list for this city if needed
            if (!restaurantsByCity.containsKey(matchedCity)) {
              restaurantsByCity[matchedCity] = [];
            }

            // Add restaurant to this city's list
            restaurantsByCity[matchedCity]!.add(restaurant);

            // Update count
            countByCity[matchedCity] = (countByCity[matchedCity] ?? 0) + 1;
          } else {
            print("WARNING: No city matched for address: $address");
          }
        }

        // Print the results for debugging
        print("Restaurants found by city:");
        countByCity.forEach((city, count) {
          print("$city: $count restaurants");
        });

        if (mounted) {
          setState(() {
            _allRestaurants = allRestaurantsData;
            _restaurantCountByCity = countByCity;
            _allRestaurantsLoaded = true;
            _isFiltering = false;
          });
        }
      } catch (error) {
        print("Error loading all restaurants: $error");
        if (mounted) {
          setState(() {
            _allRestaurantsLoaded =
                true; // Set to true on error to stop loading indicator
            _isFiltering = false;
          });

          // Don't show error if we provided restaurants directly
          if (widget.restaurants == null || widget.restaurants!.isEmpty) {
            // Show an error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading restaurants: $error'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _loadAllRestaurants(forceRefresh: true),
                ),
              ),
            );
          }
        }
      }
    }
  }

  // Enhanced helper function to extract city from address
  String _extractCityFromAddress(String address) {
    // Split the address by commas
    final parts = address.split(',');

    // Try different strategies for extraction
    if (parts.length >= 2) {
      // Typically, city is the second part in "Street, City, Country" format
      return parts[1].trim();
    } else if (parts.length == 1 && address.contains(' ')) {
      // If it's just one part, try to extract last two words as they might be the city
      final words = address.trim().split(' ');
      if (words.length > 2) {
        return '${words[words.length - 2]} ${words[words.length - 1]}';
      }
      return words.last; // Last word might be city name
    }

    return parts.isNotEmpty ? parts[0].trim() : '';
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

  // Add this helper function inside _MapWidgetState
  String _normalizeCityName(String city) {
    return city.toLowerCase().replaceAll('ü', 'u');
  }

  // Simplified method to create city markers with restaurant counts
  List<Marker> _createCityMarkers(List<Map<String, dynamic>> cities) {
    final List<Marker> cityMarkers = [];

    // Debug: Print cities data
    print("Creating markers for ${cities.length} cities");
    print("Restaurant counts available: ${_restaurantCountByCity.length}");

    for (var city in cities) {
      final cityName = city['name'] as String?;
      if (cityName == null) {
        continue; // Skip cities without names
      }

      // Get the count of restaurants for this city
      final count = _restaurantCountByCity[cityName] ?? 0;

      // Only show cities that have restaurants
      if (count <= 0) {
        print("Skipping city $cityName - no restaurants found for this city");
        continue;
      }

      // Get city coordinates
      final cityLatStr = city['latitude']?.toString() ?? '';
      final cityLngStr = city['longitude']?.toString() ?? '';

      if (cityLatStr.isEmpty || cityLngStr.isEmpty) {
        print("Skipping city $cityName - missing coordinates");
        continue;
      }

      final cityLat = double.tryParse(cityLatStr) ?? 0;
      final cityLng = double.tryParse(cityLngStr) ?? 0;

      // Skip invalid coordinates
      if (cityLat == 0 && cityLng == 0) {
        print("Skipping city $cityName - zero coordinates");
        continue;
      }

      print(
          "Adding marker for $cityName with $count restaurants at $cityLat,$cityLng");

      // Create a marker for this city with restaurant count
      cityMarkers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(cityLat, cityLng),
          child: GestureDetector(
            onTap: () {
              // Zoom in when a city cluster is tapped - set zoom to just above threshold
              _mapController.move(
                  LatLng(cityLat, cityLng), _cityClusterZoomThreshold + 0.5);

              // Update chosen city through the provider
              ref.read(chosenCityProvider.notifier).updateCity(cityName);

              // Show a snackbar with count info
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$cityName: $count restaurants found'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    print("Created ${cityMarkers.length} city markers");

    return cityMarkers;
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.restaurants if provided, otherwise use the restaurantsProvider
    // but with local state management to prevent infinite loading
    final List<Map<String, dynamic>> sourceRestaurants;

    if (widget.restaurants != null && widget.restaurants!.isNotEmpty) {
      // Use provided restaurants directly
      sourceRestaurants = widget.restaurants!;
    } else if (_allLoadedRestaurants.isNotEmpty) {
      // Use locally cached restaurants to prevent reloading
      sourceRestaurants = _allLoadedRestaurants;
    } else {
      // Fall back to provider (only on initial load)
      final restaurantsAsync = ref.watch(restaurantsNotifierProvider);

      return restaurantsAsync.when(
        data: (restaurants) {
          // Store the loaded restaurants to prevent future reloads
          if (mounted && _allLoadedRestaurants.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _allLoadedRestaurants = restaurants;
              });
              // Process cities after getting restaurants
              _loadAllRestaurants(forceRefresh: false);
            });
          }
          return _buildMapContent(restaurants);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading restaurants: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(restaurantsNotifierProvider);
                  _loadAllRestaurants(forceRefresh: true);
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Use the citiesProvider for city clusters
    final citiesAsync = ref.watch(citiesNotifierProvider);

    return citiesAsync.when(
      data: (cities) {
        return _buildMapContent(sourceRestaurants, cities: cities);
      },
      loading: () {
        // If we have restaurants already, show the map while cities load
        if (sourceRestaurants.isNotEmpty) {
          return _buildMapContent(sourceRestaurants);
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading cities data: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.refresh(citiesNotifierProvider);
                _loadAllRestaurants(forceRefresh: true);
              },
              child: const Text('Try Again'),
            )
          ],
        ),
      ),
    );
  }

  // Extract the map building logic into a separate method
  Widget _buildMapContent(List<Map<String, dynamic>> sourceRestaurants,
      {List<dynamic>? cities}) {
    List<Map<String, dynamic>> filteredRestaurants;

    // Log the number of restaurants for debugging
    print(
        "MapWidget: Using ${sourceRestaurants.length} restaurants for filtering");

    if (widget.chosenCity == 'Choose your city') {
      // Show all if no city chosen (relevant for map view)
      filteredRestaurants = sourceRestaurants;
    } else {
      // When zoomed in, show all restaurants in the chosen city
      if (_currentZoom >= _cityClusterZoomThreshold) {
        final chosenNormalized = _normalizeCityName(widget.chosenCity);
        filteredRestaurants = sourceRestaurants.where((restaurant) {
          final address =
              _normalizeCityName((restaurant['address'] ?? '').toString());
          final cityField =
              _normalizeCityName((restaurant['city'] ?? '').toString());

          // Always use normalized comparison for all cities
          return address.contains(chosenNormalized) ||
              cityField.contains(chosenNormalized);
        }).toList();
      } else {
        // When zoomed out, don't show any individual restaurants (only clusters)
        filteredRestaurants = [];
      }
    }

    print("MapWidget Build: Zoom= ${_currentZoom.toStringAsFixed(2)}, Threshold= $_cityClusterZoomThreshold, " +
        "Filtered Restaurants= ${filteredRestaurants.length}, ChosenCity= ${widget.chosenCity}");

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
                            MapEventSource.doubleTapZoomAnimationController ||
                        event.source == MapEventSource.onDrag ||
                        event.source == MapEventSource.onMultiFinger ||
                        event.source == MapEventSource.mapController ||
                        event.source == MapEventSource.scrollWheel) {
                      final newZoom = event.camera.zoom;
                      final wasShowingClusters =
                          _currentZoom < _cityClusterZoomThreshold;
                      final willShowClusters =
                          newZoom < _cityClusterZoomThreshold;

                      // Only rebuild if crossing the threshold or significant zoom change
                      if (wasShowingClusters != willShowClusters ||
                          (_currentZoom - newZoom).abs() > 0.1) {
                        setState(() {
                          _currentZoom = newZoom;
                        });
                      }
                    }
                  },
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.dinedeals.app',
                    retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
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

                  // City cluster layer (always displayed, with grouped counts)
                  if (cities != null)
                    MarkerLayer(
                      key: const ValueKey("city-clusters"),
                      markers: _createCityMarkers(
                          cities.cast<Map<String, dynamic>>()),
                    ),

                  // Individual restaurants layer (displayed when zoomed in)
                  if (_currentZoom >= _cityClusterZoomThreshold &&
                      filteredRestaurants.isNotEmpty)
                    MarkerLayer(
                      key: const ValueKey("individual-restaurants"),
                      markers: filteredRestaurants.map((restaurant) {
                        // Log some restaurants for debugging
                        if (filteredRestaurants.indexOf(restaurant) < 3) {
                          print(
                              "Creating marker for restaurant: ${restaurant['name']}");
                        }

                        // Parse coordinates more safely
                        double? lat, lng;
                        try {
                          lat = double.tryParse(
                                  restaurant['latitude']?.toString() ?? '') ??
                              zurichLat;
                          lng = double.tryParse(
                                  restaurant['longitude']?.toString() ?? '') ??
                              zurichLng;
                        } catch (e) {
                          print("Error parsing coordinates: $e");
                          lat = zurichLat;
                          lng = zurichLng;
                        }

                        final String name =
                            restaurant['name'] ?? 'Unnamed Restaurant';
                        final String address =
                            restaurant['address'] ?? 'No address';

                        return Marker(
                          width: 120.0,
                          height: 80.0,
                          point: LatLng(lat, lng),
                          child: GestureDetector(
                            onTap: () {
                              _showRestaurantCard(context, restaurant);
                            },
                            child: Column(
                              children: [
                                // Make marker more visible with a background
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.fastfood,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Attribution
                  const RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    animationConfig: ScaleRAWA(),
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                      TextSourceAttribution('CARTO'),
                    ],
                  ),
                ],
              ),

              // Loading indicator while getting all restaurants
              if (_isFiltering ||
                  (!_allRestaurantsLoaded &&
                      widget.chosenCity == 'Choose your city'))
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Loading restaurants...",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      final userLatLng =
                          LatLng(position.latitude, position.longitude);

                      // Update the user location marker
                      setState(() {
                        _userLocation = userLatLng;
                        _showUserLocation = true;
                        _currentZoom = 15.0;
                      });

                      // Move map to user location
                      _mapController.move(userLatLng, 15.0);

                      // Find nearest city and update the provider
                      await _findNearestCityAndUpdate(userLatLng);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error getting location: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Transform.rotate(
                    angle: 45 * 3.14159 / 180,
                    child: const Icon(Icons.navigation, color: Colors.white),
                  ),
                ),
              ),

              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        "Total: ${_restaurantCountByCity.values.fold(0, (sum, count) => sum + count)} restaurants",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Zoom level indicator
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

              // Add debug overlay to show current view mode
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _currentZoom < _cityClusterZoomThreshold
                        ? "Cities View"
                        : "Restaurants View",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom controls
        // MapBottomControls(
        //   onAllCities: () {
        //     setState(() {
        //       _currentZoom = 8.0;
        //     });
        //     _mapController.move(const LatLng(zurichLat, zurichLng), 8.0);
        //     _loadAllRestaurants(forceRefresh: false);
        //   },
        //   onZoomIn: _zoomIn,
        //   onZoomOut: _zoomOut,
        // ),
      ],
    );
  }

  // Add a method to find the nearest city based on user location
  Future<void> _findNearestCityAndUpdate(LatLng userLocation) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finding nearest city...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Get cities data
      final citiesAsync = ref.read(citiesNotifierProvider);
      final cities = await citiesAsync.when(
        data: (data) => Future.value(data),
        loading: () => throw Exception('Cities data is still loading'),
        error: (error, _) => throw Exception('Error loading cities: $error'),
      );

      if (!mounted) return;

      if (cities.isEmpty) {
        throw Exception('No cities available');
      }

      // Find the nearest city by calculating distance
      double nearestDistance = double.infinity;
      Map<String, dynamic>? nearestCity;

      for (final city in cities) {
        if (city['latitude'] == null || city['longitude'] == null) continue;

        // Parse city coordinates
        final cityLat = double.tryParse(city['latitude'].toString());
        final cityLng = double.tryParse(city['longitude'].toString());

        if (cityLat == null || cityLng == null) continue;

        // Calculate distance using the Distance class
        final distance = const Distance().as(
          LengthUnit.Kilometer,
          userLocation,
          LatLng(cityLat, cityLng),
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestCity = city;
        }
      }

      if (!mounted) return;

      if (nearestCity != null) {
        final cityName = nearestCity['name'] as String;

        // Update the chosen city using the provider
        ref.read(chosenCityProvider.notifier).updateCity(cityName);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Nearest city found: $cityName (${nearestDistance.toStringAsFixed(1)} km away)'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Center map on the city (use a slight delay to ensure provider updates first)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _centerOnChosenCity();
          }
        });
      } else {
        throw Exception('No cities with valid coordinates found');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding nearest city: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestaurantCard(
      BuildContext context, Map<String, dynamic> restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
              bottom: 135), // Above filter/list-map buttons
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            restaurant['imageUrl'] ??
                                'https://kpceyekfdauxsbljihst.supabase.co/storage/v1/object/public/pictures//cheeseburger-7580676_1280.jpg',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant,
                                    color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                restaurant['name'] ?? 'No name',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Stars, distance, address
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  Text(' ${restaurant['rating'] ?? '4.5'} · '),
                                  if (restaurant['distance'] != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.directions,
                                            size: 16, color: Colors.blue),
                                        Text(
                                            ' ${(restaurant['distance'] as double).toStringAsFixed(1)} km · '),
                                      ],
                                    ),
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  Expanded(
                                    child: Text(
                                      restaurant['address']?.split(',').first ??
                                          'No address',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Offers
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (restaurant['deals'] as List? ?? [])
                                    .take(3)
                                    .map((deal) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            deal['name']?.toString() ??
                                                'Special Offer',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
