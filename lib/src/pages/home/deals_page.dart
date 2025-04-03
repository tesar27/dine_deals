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
              onMarkerTapped: (restaurantName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: $restaurantName'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      color: _isMapView ? Colors.grey[300] : Colors.grey[700],
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
                      color: _isMapView ? Colors.grey[700] : Colors.grey[300],
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
        ],
      ),
    );
  }
}
