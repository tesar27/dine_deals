import 'package:dine_deals/src/providers/cities_provider.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';
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
  static const String _filtersPreferenceKey = 'selected_filters';
  String _chosenCity = 'Choose your city';
  bool _iconTapped = false;
  bool _isMapView = false;
  List<String> _selectedCategories = ["All"]; // Default to "All"
  List<Map<String, dynamic>> _filteredRestaurants = [];
  bool _isLoadingRestaurants = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
    _loadSavedFilters();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If city is already loaded, fetch restaurants
    if (_chosenCity != 'Choose your city') {
      _fetchFilteredRestaurants();
    }
  }

// Load city from SharedPreferences
  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_cityPreferenceKey);
    if (savedCity != null) {
      setState(() {
        _chosenCity = savedCity;
      });
      // Fetch restaurants after setting the city
      _fetchFilteredRestaurants();
    }
  }

  // Save city to SharedPreferences
  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPreferenceKey, city);
    // Fetch restaurants with new city filter
    _fetchFilteredRestaurants();
  }

  void _showCitiesList(List<String> cities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.95, // 80% of screen height
          padding: EdgeInsets.only(
            top: 14.0, // Extra top padding for dragging space
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              // Drag indicator and close button row
              Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered drag indicator
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Close button on the right
                    Positioned(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(
                        cities[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
            ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                // Drag indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // Reset the temporary selections
                              selectedTags.value = ["All"];
                              tempSelectedCategories.clear();
                              tempSelectedCategories.add("All");
                              // You don't update state here yet
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor),
                // Categories section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                                    label: Text(
                                      name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                      ),
                                    ),
                                    onSelected: (isSelected) {
                                      if (name == "All" && isSelected) {
                                        selectedTags.value = ["All"];
                                        tempSelectedCategories.clear();
                                        tempSelectedCategories.add("All");
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
                        // Save filters to SharedPreferences
                        _saveFilters(_selectedCategories);
                        // Apply the filters by fetching filtered restaurants
                        Navigator.pop(context); // First close the modal
                        // Then fetch with a slight delay to ensure UI is updated
                        Future.microtask(() => _fetchFilteredRestaurants());
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

// Save filters to SharedPreferences
  Future<void> _saveFilters(List<String> filters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_filtersPreferenceKey, filters);
  }

  // Load filters from SharedPreferences
  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilters = prefs.getStringList(_filtersPreferenceKey);
    if (savedFilters != null && savedFilters.isNotEmpty) {
      setState(() {
        _selectedCategories = savedFilters;
      });
      // Fetch restaurants with saved filters if city is already selected
      if (_chosenCity != 'Choose your city') {
        _fetchFilteredRestaurants();
      }
    }
  }

  Future<void> _fetchFilteredRestaurants() async {
    // Don't fetch if city isn't selected
    if (_chosenCity == 'Choose your city') return;

    setState(() {
      _isLoadingRestaurants = true;
    });

    try {
      // Get the restaurants provider
      final restaurantsNotifier =
          ref.read(restaurantsNotifierProvider.notifier);

      // Get category filter (null if "All" is selected)
      final categoryFilter = _selectedCategories.contains("All")
          ? null
          : _selectedCategories.isNotEmpty
              ? _selectedCategories[0]
              : null;

      print(
          "Applying filter: City=$_chosenCity, Category=$categoryFilter"); // Debug print

      // Fetch filtered restaurants
      final results = await restaurantsNotifier.getFilteredRestaurants(
        city: _chosenCity,
        category: categoryFilter,
      );

      setState(() {
        _filteredRestaurants =
            results is List ? results.cast<Map<String, dynamic>>() : [];
        _isLoadingRestaurants = false;
      });

      print("Found ${_filteredRestaurants.length} restaurants"); // Debug print
    } catch (error) {
      print("Error fetching restaurants: $error"); // Debug print
      setState(() {
        _isLoadingRestaurants = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading restaurants: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesNotifierProvider);
    final restaurantsAsync = ref.watch(restaurantsNotifierProvider);

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
          // Keep MapWidget in the tree but control visibility
          Visibility(
            visible: _isMapView,
            maintainState: true,
            child: MapWidget(
              key: ValueKey(_chosenCity),
              onMarkerTapped: (restaurantName) {},
              chosenCity: _chosenCity,
              isVisible: _isMapView,
            ),
          ),

          Visibility(
            visible: !_isMapView,
            maintainState: true,
            child: _isLoadingRestaurants
                ? const Center(child: CircularProgressIndicator())
                : _chosenCity == 'Choose your city'
                    ? Center(
                        child: Text(
                          'Please select a city first',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      )
                    : _filteredRestaurants.isEmpty
                        ? Center(
                            child: Text(
                              'No restaurants found for the selected filters',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : SizedBox.expand(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Found ${_filteredRestaurants.length} restaurants',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredRestaurants.length,
                                    itemBuilder: (context, index) {
                                      final restaurant =
                                          _filteredRestaurants[index];
                                      return ListTile(
                                        title: Text(
                                            restaurant['name'] ?? 'No name'),
                                        subtitle: Text(restaurant['address'] ??
                                            'No address'),
                                        onTap: () {
                                          // Navigate to restaurant detail page
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
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
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter ${_selectedCategories.contains("All") ? "" : "(${_selectedCategories.length})"}',
                                  style: const TextStyle(
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

                              // If switching to map view, give the map time to render
                              // then trigger a refresh
                              if (_isMapView) {
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  setState(() {
                                    // This empty setState forces a rebuild after the map is visible
                                  });
                                });
                              }
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
