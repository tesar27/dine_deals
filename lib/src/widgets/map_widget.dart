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

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAllRestaurants();
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
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _loadAllRestaurants();
    }
    
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

  // Load all restaurants and count by city - fixed to correctly match cities
  Future<void> _loadAllRestaurants() async {
    if (mounted) {
      setState(() {
        _allRestaurantsLoaded = false;
      });
      
      try {
        // Step 1: Get cities data first
        final citiesAsync = ref.read(citiesNotifierProvider);
        final cities = await citiesAsync.when(
          data: (data) => Future.value(data),
          loading: () => Future<List<Map<String, dynamic>>>.delayed(
            const Duration(seconds: 1),
            () => throw Exception('Cities still loading'),
          ),
          error: (error, _) => throw Exception('Failed to load cities: $error'),
        );
        
        // Step 2: Get restaurants data
        final restaurantsNotifier = ref.read(restaurantsNotifierProvider.notifier);
        final allRestaurantsData = await restaurantsNotifier.fetchRestaurants(forceRefresh: false);
        
        if (!mounted) return;
        
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
          });
        }
      } catch (error) {
        print("Error loading all restaurants: $error");
        if (mounted) {
          setState(() {
            _allRestaurantsLoaded = true; // Set to true to stop loading indicator
          });
          
          // Show an error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading restaurants: $error'),
              backgroundColor: Colors.red,
            ),
          );
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
      
      print("Adding marker for $cityName with $count restaurants at $cityLat,$cityLng");

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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cityName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.black87,
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
                                event.source == MapEventSource.flingAnimationController ||
                                event.source == MapEventSource.doubleTapZoomAnimationController) {
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
                            key: ValueKey("markers-${_currentZoom < _cityClusterZoomThreshold}"),
                            markers: _currentZoom < _cityClusterZoomThreshold
                                ? _createCityMarkers(cities)  // Show city clusters when zoomed out
                                : filteredRestaurants.map((restaurant) {
                                    final double lat = restaurant['latitude'] != null
                                        ? double.parse(restaurant['latitude'].toString())
                                        : zurichLat;

                                    final double lng = restaurant['longitude'] != null
                                        ? double.parse(restaurant['longitude'].toString())
                                        : zurichLng;

                                    final String name = restaurant['name'] ?? 'Unnamed Restaurant';
                                    final String address = restaurant['address'] ?? 'No address';

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
                                                  onPressed: () => Navigator.of(context).pop(),
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
                      
                      // Loading indicator while getting all restaurants
                      if (!_allRestaurantsLoaded)
                        Positioned(
                          top: 60,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                    "Loading all restaurants...",
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
                              final userLatLng = LatLng(position.latitude, position.longitude);
                              
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              const Icon(Icons.restaurant, size: 16, color: Colors.blue),
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

                      // Add zoom feedback indicator when near threshold
                      if (_currentZoom >= _cityClusterZoomThreshold - 1 && 
                          _currentZoom <= _cityClusterZoomThreshold + 1)
                        Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: (_currentZoom < _cityClusterZoomThreshold) ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Zoom in to see individual restaurants",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                        onPressed: () {
                          // Zoom out to see all cities with counts
                          setState(() {
                            _currentZoom = 8.0; // Zoom level for overview
                          });
                          _mapController.move(const LatLng(zurichLat, zurichLng), 8.0);
                          _loadAllRestaurants(); // Refresh data
                        },
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
            content: Text('Nearest city found: $cityName (${nearestDistance.toStringAsFixed(1)} km away)'),
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
}
