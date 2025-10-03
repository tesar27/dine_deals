import 'package:flutter/material.dart';

class HeroCarousel extends StatelessWidget {
  const HeroCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = [
      {'text': '50% Off', 'color': Colors.red},
      {'text': '1+1 Top Deals', 'color': Colors.blue},
      {'text': 'Top Restaurants', 'color': Colors.green},
    ];

    return SizedBox(
      height: 200,
      child: PageView(
        children: offers.map((offer) {
          return Padding(
            padding:
                const EdgeInsets.all(8.0), // Add padding around each container
            child: Container(
              decoration: BoxDecoration(
                color: offer['color'] as Color,
                borderRadius: BorderRadius.circular(10), // Add rounded corners
              ),
              child: Center(
                child: Text(
                  offer['text'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
