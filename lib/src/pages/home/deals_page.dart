import 'package:dine_deals/src/providers/cities_provider.dart';
import 'package:dine_deals/src/widgets/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealsPage extends ConsumerStatefulWidget {
  const DealsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DealsPageState createState() => _DealsPageState();
}

class _DealsPageState extends ConsumerState<DealsPage> {
  static const String _cityPreferenceKey = 'chosen_city';
  String _chosenCity = 'Choose your city';
  bool _iconTapped = false;
  bool _isMapView = false;
  List<String> _selectedCategories = ["All"]; // Default to "All"

  @override
  void initState() {
    super.initState();
    // Load saved city when widget initializes
    _loadSavedCity();
  }

// Load city from SharedPreferences
  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_cityPreferenceKey);
    if (savedCity != null) {
      setState(() {
        _chosenCity = savedCity;
      });
    }
  }

  // Save city to SharedPreferences
  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPreferenceKey, city);
  }

  void _showCitiesList(List<String> cities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.92,
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    cities[index],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _chosenCity = cities[index];
                      _iconTapped = false;
                    });
                    // Save city when selected
                    _saveCity(cities[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    final tempSelectedCategories = [..._selectedCategories];
    // Use the temporary list for ValueNotifier
    final selectedTags = ValueNotifier<List<String>>(tempSelectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Reset the temporary selections
                          selectedTags.value = ["All"];
                          tempSelectedCategories.clear();
                          tempSelectedCategories.add("All");
                          // You don't update state here yet
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Categories section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
                // Categories chips - in a scrollable area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        // Categories list
                        final categories = [
                          {"name": "All", "icon": Icons.fastfood},
                          {"name": "Meat", "icon": Icons.dinner_dining},
                          {"name": "Cafe", "icon": Icons.coffee},
                          {"name": "Drinks", "icon": Icons.local_bar},
                          {"name": "Desserts", "icon": Icons.cake},
                          {"name": "Vegan", "icon": Icons.eco},
                          {"name": "Pasta", "icon": Icons.ramen_dining},
                          {"name": "Burger", "icon": Icons.lunch_dining},
                          {"name": "Doner", "icon": Icons.kebab_dining},
                          {"name": "Sushi", "icon": Icons.set_meal},
                          {"name": "Pizza", "icon": Icons.local_pizza},
                          {"name": "Seafood", "icon": Icons.water},
                        ];

                        return ValueListenableBuilder<List<String>>(
                          valueListenable: selectedTags,
                          builder: (context, selected, _) {
                            return SingleChildScrollView(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: categories.map((category) {
                                  final name = category["name"] as String;
                                  final icon = category["icon"] as IconData;
                                  final isSelected = selected.contains(name);

                                  return FilterChip(
                                    selected: isSelected,
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Colors.blue[100],
                                    checkmarkColor: Colors.blue[800],
                                    avatar: Icon(icon, size: 18),
                                    label: Text(name),
                                    onSelected: (isSelected) {
                                      if (name == "All" && isSelected) {
                                        selectedTags.value = ["All"];
                                      } else if (isSelected) {
                                        final newList = selected
                                            .where((tag) => tag != "All")
                                            .toList()
                                          ..add(name);
                                        selectedTags.value = newList;
                                        // Update temporary list
                                        tempSelectedCategories.clear();
                                        tempSelectedCategories.addAll(newList);
                                      } else {
                                        final newList = selected
                                            .where((tag) => tag != name)
                                            .toList();
                                        if (newList.isEmpty) {
                                          selectedTags.value = ["All"];
                                          tempSelectedCategories.clear();
                                          tempSelectedCategories.add("All");
                                        } else {
                                          selectedTags.value = newList;
                                          tempSelectedCategories.clear();
                                          tempSelectedCategories
                                              .addAll(newList);
                                        }
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Actually update the state with the temporary selections
                        setState(() {
                          _selectedCategories = [...tempSelectedCategories];
                        });
                        // Apply the filters by fetching filtered restaurants
                        _fetchFilteredRestaurants();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _iconTapped = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _iconTapped = false;
                  });
                  citiesAsync.when(
                    data: (cities) => _showCitiesList(
                      cities.map((city) => city['name'] as String).toList(),
                    ),
                    loading: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading cities...')),
                    ),
                    error: (error, stack) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    ),
                  );
                },
                onTapCancel: () {
                  setState(() {
                    _iconTapped = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _iconTapped
                        ? const Color.fromARGB(255, 106, 108, 107)
                        : const Color.fromARGB(255, 78, 75, 75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_chosenCity),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isMapView)
            MapWidget(
              onMarkerTapped: (restaurantName) {},
              chosenCity: _chosenCity,
            )
          else
            const SizedBox.expand(
              // <-- Use SizedBox.expand instead of Expanded
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bottom button row
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Filter Button
                        GestureDetector(
                          onTap: () {
                            _showFilterModal(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.filter_list,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Map/List Toggle Button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMapView = !_isMapView;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isMapView ? Icons.list : Icons.map,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isMapView ? 'List' : 'Map',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right aligned button
                // if (_isMapView)
                //   Positioned(
                //     right: 0,
                //     child: FloatingActionButton(
                //       heroTag: 'locate_me',
                //       mini: true,
                //       shape: const CircleBorder(),
                //       backgroundColor: Colors.blue,
                //       elevation: 0, // Remove shadow
                //       onPressed: () async {
                //         try {
                //           // Show a loading message
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             const SnackBar(
                //                 content: Text('Fetching location...')),
                //           );

                //           // Get location
                //           final position = await Geolocator.getCurrentPosition(
                //             locationSettings: const LocationSettings(
                //               accuracy: LocationAccuracy.high,
                //             ),
                //           );

                //           // Get map controller
                //           final mapController = ref.read(mapControllerProvider);
                //           print('Map controller: $mapController');
                //           print(
                //               'Location: ${position.latitude}, ${position.longitude}');

                //           // Move map to user location
                //           // Create LatLng object from position
                //           final latLng =
                //               LatLng(position.latitude, position.longitude);

                //           // Use a microtask to ensure UI updates after current execution
                //           Future.microtask(() {
                //             if (mapController != null) {
                //               mapController.move(latLng, 15.0);
                //             }
                //             print('Map moved to: $latLng');

                //             // Show success message
                //             ScaffoldMessenger.of(context).showSnackBar(
                //               const SnackBar(
                //                   content: Text('Centered on your location')),
                //             );
                //           });
                //         } catch (e) {
                //           // Show error message
                //           print('Location error: $e');
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             SnackBar(
                //               content: Text('Error: $e'),
                //               backgroundColor: Colors.red,
                //             ),
                //           );
                //         }
                //       },
                //       child: Transform.rotate(
                //         angle: 45 * 3.14159 / 180, // 45 degrees in radians
                //         child:
                //             const Icon(Icons.navigation, color: Colors.white),
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _fetchFilteredRestaurants() {}
