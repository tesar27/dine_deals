import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/providers/app_data_provider.dart';
import 'package:dine_deals/pages/details/edit_place_details.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dine_deals/models/restaurant_model.dart';
import 'dart:io';

/// AdminPage - allows admin users to view, add, edit, delete and upload
/// images for restaurants. This page converts raw provider rows into
/// typed `Restaurant` models at the rendering boundary to keep the UI
/// type-safe while the provider continues returning map-based data.
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  List<Restaurant>? _filteredRestaurants;
  bool _isSearching = false;

  @override
  void dispose() {
    nameController.dispose();
    cityController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    try {
      final results = await ref
          .read(restaurantDataProvider.notifier)
          .getFilteredRestaurantsTyped(
            name: nameController.text,
            city: cityController.text,
            country: countryController.text,
          );
      setState(() {
        _filteredRestaurants = results;
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    nameController.clear();
    cityController.clear();
    countryController.clear();
    setState(() {
      _filteredRestaurants = null;
    });
    ref.invalidate(restaurantDataProvider);
  }

  Future<void> _pickAndUploadImage(BuildContext context, Restaurant restaurant) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image == null) return;

      final file = File(image.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));

      final newUrl = await ref.read(restaurantDataProvider.notifier).uploadImage(file, restaurantId: restaurant.id);
      if (newUrl != null) {
        try {
          await ref.read(restaurantDataProvider.notifier).updateRestaurantImage(restaurant.id, newUrl);
          ref.invalidate(restaurantDataProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image updated successfully!'), backgroundColor: Colors.green));
          }
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploaded but failed to update DB: $e'), backgroundColor: Colors.orange));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint('Image pick/upload error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddPlaceDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Place'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final address = addressCtrl.text.trim();
                if (name.isEmpty || address.isEmpty) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange));
                  return;
                }
                Navigator.pop(context);
                try {
                  await ref.read(restaurantDataProvider.notifier).addPlace(name: name, address: address);
                  ref.invalidate(restaurantDataProvider);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New place added successfully!'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding place: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  List<Restaurant> _toTypedList(List<dynamic> rawList) {
    return rawList.map<Restaurant>((raw) {
      if (raw is Restaurant) return raw;
      if (raw is Map<String, dynamic>) return Restaurant.fromMap(raw);
      // Fallback - try to convert dynamic map-like object
      return Restaurant.fromMap(Map<String, dynamic>.from(raw as Map));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(restaurantDataProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: countryController, decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _isSearching ? null : _performSearch, child: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Search')),
                const SizedBox(width: 8),
                TextButton(onPressed: _clearSearch, child: const Text('Clear')),
              ],
            ),
          ),
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                final listToShow = _filteredRestaurants ?? _toTypedList(restaurants);
                if (listToShow.isEmpty) return const Center(child: Text('No restaurants found'));
                return ListView.separated(
                  itemCount: listToShow.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = listToShow[index];
                    final displayImage = r.imageUrl ?? 'https://kpceyekfdauxsbljihst.supabase.co/storage/v1/object/public/pictures//cheeseburger-7580676_1280.jpg';
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          displayImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
                        ),
                      ),
                      title: Text(r.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (r.rating != null) Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), const SizedBox(width: 4), Text(r.rating!.toStringAsFixed(1))]),
                          if (r.address.isNotEmpty) Text(r.address),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _pickAndUploadImage(context, r)),
                          IconButton(icon: const Icon(Icons.edit), onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EditPlaceDetails(restaurant: r))).then((_) => ref.invalidate(restaurantDataProvider));
                          }),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete place'),
                                content: Text('Are you sure you want to delete ${r.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              try {
                                await ref.read(restaurantDataProvider.notifier).deleteRestaurant(r.id);
                                ref.invalidate(restaurantDataProvider);
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place deleted'), backgroundColor: Colors.green));
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red));
                              }
                            }
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddPlaceDialog, child: const Icon(Icons.add)),
    );
  }
}

