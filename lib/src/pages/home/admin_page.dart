import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsNotifierProvider);
    // Local state for filters
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Restaurants'),
      ),
      // Add filter section below the app bar
      persistentFooterButtons: [
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First row - Name filter
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name of the place',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          // Get filtered results
                          final filtered = await ref
                              .read(restaurantsNotifierProvider.notifier)
                              .getFilteredRestaurants(
                                name: nameController.text,
                                city: cityController.text,
                                country: countryController.text,
                              );
                          // Convert to List if it's a single item
                          final filteredList = filtered is Map
                              ? [filtered as Map<String, dynamic>]
                              : filtered as List<Map<String, dynamic>>;

                          // Update the provider state with filtered results
                          ref
                              .read(restaurantsNotifierProvider.notifier)
                              .updateFilteredResults(filteredList);
                          // Example query to supabase using the filter values
                          // ref.read(restaurantsNotifierProvider.notifier).filterRestaurants(
                          //   name: nameController.text,
                          //   city: cityController.text,
                          //   country: countryController.text,
                          // );
                          //
                          // In the provider:
                          // Future<void> filterRestaurants({String? name, String? city, String? country}) async {
                          //   final query = supabase.from('restaurants').select();
                          //   if (name != null && name.isNotEmpty) {
                          //     query.ilike('name', '%$name%');
                          //   }
                          //   if (city != null && city.isNotEmpty) {
                          //     query.eq('city', city);
                          //   }
                          //   if (country != null && country.isNotEmpty) {
                          //     query.eq('country', country);
                          //   }
                          //   final data = await query;
                          //   state = AsyncData(data);
                          // }
                        },
                      ),
                    ),
                  ),
                ),
                // Second row - City and Country filters
                Row(
                  children: [
                    // City filter
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    // Country filter
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
      body: restaurantsAsync.when(
        data: (restaurants) => ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      restaurant['imageUrl'] ??
                          'https://kpceyekfdauxsbljihst.supabase.co/storage/v1/object/public/pictures//cheeseburger-7580676_1280.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side - Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First row - Restaurant name
                        Text(
                          restaurant['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Second row - Rating, distance, category
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            Text(' ${restaurant['rating'] ?? '4.5'} · '),
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            Text(' ${restaurant['distance'] ?? '1.2 km'} · '),
                            Text(restaurant['category'] ?? 'Restaurant',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Third row - Offers
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var offer in restaurant['offers'] ??
                                ['2for1 Burger', 'FREE Soft Drink'])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  offer,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlaceDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddPlaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Place'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final address = addressController.text.trim();

                if (name.isNotEmpty && address.isNotEmpty) {
                  try {
                    await ref
                        .read(restaurantsNotifierProvider.notifier)
                        .addPlace(
                          name: name,
                          address: address,
                        );
                    Navigator.pop(context);
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
