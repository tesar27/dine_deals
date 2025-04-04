import 'package:dine_deals/src/providers/cities_provider.dart';
import 'package:dine_deals/src/widgets/food_categories.dart';
import 'package:dine_deals/src/widgets/hero_carousel.dart';
import 'package:dine_deals/src/widgets/offers_list.dart';
import 'package:dine_deals/src/widgets/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DealsPage extends ConsumerStatefulWidget {
  const DealsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DealsPageState createState() => _DealsPageState();
}

class _DealsPageState extends ConsumerState<DealsPage> {
  String _chosenCity = 'Choose your city';
  bool _iconTapped = false;
  bool _isMapView = false;

  void _showCitiesList(List<String> cities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
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
            const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FoodCategories(),
                  HeroCarousel(),
                  OffersList(),
                ],
              ),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center toggle buttons
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40), // Add padding to center
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Make row take minimum space
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMapView = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            decoration: BoxDecoration(
                              color: _isMapView
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                            child: Text(
                              'List',
                              style: TextStyle(
                                color: _isMapView ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMapView = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 24),
                            decoration: BoxDecoration(
                              color: _isMapView
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Map',
                              style: TextStyle(
                                color: _isMapView ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
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
