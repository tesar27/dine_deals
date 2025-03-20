import 'package:dine_deals/src/pages/details/offer_details_page.dart';
import 'package:dine_deals/src/widgets/page_route_with_fade_transition.dart';
import 'package:flutter/material.dart';

class OffersList extends StatelessWidget {
  const OffersList({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = [
      {'name': '1+1 Pizza', 'restaurant': 'Italian Place', 'rating': '4.5'},
      {'name': '2+1 Döner', 'restaurant': 'Turkish Place', 'rating': '4.2'},
      {'name': '1+1 Sushi Set', 'restaurant': 'Sushi Place', 'rating': '4.8'},
      {'name': '2+1 Pho', 'restaurant': 'Vietnamese Place', 'rating': '4.6'},
      {'name': '1+1 Burger', 'restaurant': 'American Place', 'rating': '4.3'},
      {'name': '2+1 Tacos', 'restaurant': 'Mexican Place', 'rating': '4.7'},
      {'name': '1+1 Curry', 'restaurant': 'Indian Place', 'rating': '4.4'},
      {
        'name': '2+1 Spring Rolls',
        'restaurant': 'Chinese Place',
        'rating': '4.5'
      },
      {'name': '1+1 Salad', 'restaurant': 'Healthy Place', 'rating': '4.6'},
      {'name': '2+1 Pasta', 'restaurant': 'Italian Place', 'rating': '4.7'},
    ];

    return Column(
      children: offers.map((offer) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteWithFadeTransition(
                page: OfferDetailsPage(offer: offer),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(offer['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer['restaurant'] as String),
                      Text('Rating: ${offer['rating']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
