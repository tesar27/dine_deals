import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';
import 'package:dine_deals/src/pages/details/edit_place_details.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        actions: [
          // Add a refresh button to the app bar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh the restaurants list
              ref.invalidate(restaurantsNotifierProvider);
            },
          ),
        ],
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
        data: (restaurants) {
          // Debug print to check the data
          debugPrint('Loaded ${restaurants.length} restaurants');
          return restaurants.isEmpty
              ? const Center(child: Text('No restaurants found'))
              : ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Image with clickable behavior
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _pickAndUploadImage(
                                    context, ref, restaurant),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    restaurant['imageUrl'] ??
                                        'https://kpceyekfdauxsbljihst.supabase.co/storage/v1/object/public/pictures//cheeseburger-7580676_1280.jpg',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, _) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ),
                              // Overlay camera icon to indicate image is clickable
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Right side - Information (clickable to edit details)
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // Navigate to edit details page when restaurant info is tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPlaceDetails(
                                      restaurant: restaurant,
                                    ),
                                  ),
                                ).then((_) {
                                  // Refresh the list when returning from edit page
                                  ref.invalidate(restaurantsNotifierProvider);
                                });
                              },
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
                                      Text(
                                          ' ${restaurant['rating'] ?? '4.5'} · '),
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.grey),
                                      Text(
                                          ' ${restaurant['distance'] ?? '1.2 km'} · '),
                                      Text(
                                          restaurant['category'] ??
                                              'Restaurant',
                                          style: TextStyle(
                                              color: Colors.grey[600])),
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
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                          ),
                        ],
                      ),
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlaceDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method to handle image picking and uploading
  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref,
      Map<String, dynamic> restaurant) async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null) {
        // User cancelled the picker
        return;
      }

      if (context.mounted) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get the file path
      final String filePath = image.path;
      final File file = File(filePath);

      // Upload the image using the provider
      final String? newImageUrl = await ref
          .read(restaurantsNotifierProvider.notifier)
          .uploadImage(file, restaurantId: restaurant['id']);

      if (newImageUrl != null && context.mounted) {
        // Update the restaurant with new image URL
        await ref
            .read(restaurantsNotifierProvider.notifier)
            .updateRestaurantImage(restaurant['id'], newImageUrl);

        // Refresh the list
        ref.invalidate(restaurantsNotifierProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking or uploading image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    debugPrint('Checking if place exists: $name, $address');
                    // Check if restaurant with same name and address already exists
                    final exists = await ref
                        .read(restaurantsNotifierProvider.notifier)
                        .checkPlaceExists(name: name, address: address);

                    if (exists) {
                      if (context.mounted) {
                        // Close the dialog
                        Navigator.pop(context);

                        // Show already exists message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Place already exists!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }

                    debugPrint('Adding new place: $name, $address');
                    await ref
                        .read(restaurantsNotifierProvider.notifier)
                        .addPlace(
                          name: name,
                          address: address,
                        );

                    // Directly invalidate the provider to force a refresh
                    ref.invalidate(restaurantsNotifierProvider);

                    // Also try direct fetch to ensure we get new data
                    await Future.delayed(const Duration(milliseconds: 300));
                    await ref
                        .read(restaurantsNotifierProvider.notifier)
                        .fetchRestaurants();

                    debugPrint('Place added and data refreshed');

                    if (context.mounted) {
                      // Close the dialog
                      Navigator.pop(context);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New place added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (error) {
                    debugPrint('Error adding place: $error');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
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
