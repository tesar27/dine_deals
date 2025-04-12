import 'package:flutter/material.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Latest News'),
          _buildCard(
            title: 'Exciting Updates in the Food World!',
            subtitle: 'Discover the latest trends and news in dining.',
            imageUrl: 'https://placehold.co/150',
          ),
          _buildSectionTitle('New Offers'),
          _buildCard(
            title: '50% Off on Your Favorite Meals!',
            subtitle: 'Limited time offer. Grab it now!',
            imageUrl: 'https://via.placeholder.com/150',
          ),
          _buildSectionTitle('New Places'),
          _buildCard(
            title: 'Explore the Newest Restaurants in Town',
            subtitle: 'Find your next favorite dining spot.',
            imageUrl: 'https://via.placeholder.com/150',
          ),
          _buildSectionTitle('Recent Feedbacks'),
          _buildCard(
            title: 'Customer Reviews You Should Check Out',
            subtitle: 'See what others are saying about top places.',
            imageUrl: 'https://via.placeholder.com/150',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required String subtitle,
      required String imageUrl}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
