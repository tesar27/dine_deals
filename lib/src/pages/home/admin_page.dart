import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  static final List<Map<String, String>> restaurants = [
    {
      'name': 'The Gourmet Kitchen',
      'address': '123 Foodie Lane',
      'phone': '123-456-7890',
      'banner': 'assets/images/gourmet_kitchen.jpg',
    },
    {
      'name': 'Pizza Paradise',
      'address': '456 Cheesy Blvd',
      'phone': '987-654-3210',
      'banner': 'assets/images/pizza_paradise.jpg',
    },
    {
      'name': 'Sushi World',
      'address': '789 Ocean Drive',
      'phone': '555-123-4567',
      'banner': 'assets/images/sushi_world.jpg',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(restaurant['banner']!),
            ),
            title: Text(restaurant['name']!),
            subtitle: Text(restaurant['address']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantEditPage(
                    restaurant: restaurant,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a new page to add a restaurant
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RestaurantEditPage extends StatefulWidget {
  final Map<String, String> restaurant;

  const RestaurantEditPage({super.key, required this.restaurant});

  @override
  _RestaurantEditPageState createState() => _RestaurantEditPageState();
}

class _RestaurantEditPageState extends State<RestaurantEditPage> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.restaurant['name']);
    addressController =
        TextEditingController(text: widget.restaurant['address']);
    phoneController = TextEditingController(text: widget.restaurant['phone']);
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Restaurant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save restaurant details
              },
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to add/edit offer page
              },
              child: const Text('Add/Edit Offer'),
            ),
          ],
        ),
      ),
    );
  }
}
