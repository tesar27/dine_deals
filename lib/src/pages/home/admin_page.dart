import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/restaurants_provider.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Restaurants'),
      ),
      body: restaurantsAsync.when(
        data: (restaurants) => ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return ListTile(
              title: Text(restaurant['name']),
              subtitle: Text(restaurant['address']),
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
