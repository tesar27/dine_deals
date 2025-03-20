import 'package:flutter/material.dart';

class FoodCategories extends StatelessWidget {
  const FoodCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Fast Food',
      'Pizza',
      'Asian',
      'Sushi',
      'Burgers',
      'Mexican',
      'Indian',
      'Chinese',
      'American',
      'Healthy',
      'Italian',
      'Japanese',
      'Salads',
      'Greek',
      'Vietnamese',
      'Sandwich',
      'Seafood'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}
