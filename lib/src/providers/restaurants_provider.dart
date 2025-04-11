import 'dart:convert';
import 'package:dine_deals/src/config/config.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'restaurants_provider.g.dart';

@riverpod
class RestaurantsNotifier extends _$RestaurantsNotifier {
  PostgrestList? _cachedData;
  static const String _cacheKey = 'places_cache';

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchRestaurants();
  }

  // Fetch the list of restaurants from Supabase
  Future<List<Map<String, dynamic>>> _fetchRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _cachedData = PostgrestList.from(decoded);
        print("PlacesNotifier: Returning data from SharedPreferences");
        return _cachedData!;
      } catch (e) {
        print("PlacesNotifier: Error parsing cached data: $e");
        // Continue to fetch from API if parsing fails
      }
    }

    try {
      final placesData = await Supabase.instance.client
          .from('restaurants')
          .select()
          .order('name', ascending: true);

      try {
        await prefs.setString(_cacheKey, jsonEncode(placesData));
        print("CitiesNotifier: Data saved to SharedPreferences");
      } catch (e) {
        print("CitiesNotifier: Error saving to SharedPreferences: $e");
      }
      _cachedData = placesData;
      return (placesData as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (error) {
      throw Exception('Failed to fetch restaurants: $error');
    }
  }

  // Add a new place (admin functionality)
  Future<void> addPlace({
    required String name,
    required String address,
  }) async {
    try {
      // Step 1: Get coordinates from OpenCage API
      final coordinates = await _getCoordinatesFromAddress(address);

      // Step 2: Save the new place in Supabase
      await Supabase.instance.client.from('restaurants').insert({
        'name': name,
        'address': address,
        'latitude': coordinates['lat'],
        'longitude': coordinates['lng'],
      });

      // Step 3: Refresh the list of restaurants
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to add place: $error');
    }
  }

  // Helper function to get coordinates from OpenCage API
  Future<Map<String, double>> _getCoordinatesFromAddress(String address) async {
    final apiKey = Config.opencageApi; // Replace with your OpenCage API key
    final url =
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(address)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
        };
      } else {
        throw Exception('No results found for the given address.');
      }
    } else {
      throw Exception('Failed to fetch coordinates: ${response.body}');
    }
  }

  // Add this function to your RestaurantsNotifier class

  /// Fetches restaurants and filters them based on provided criteria
  /// Returns either a list of matching restaurants or a single restaurant if unique match
  Future<dynamic> getFilteredRestaurants({
    String? city,
    String? country,
    String? name,
    String? category,
    double? minRating,
    double? maxPrice,
    int? limit,
  }) async {
    try {
      // First, get all restaurants (leveraging cache if available)
      final allRestaurants = await _fetchRestaurants();

      // Apply filters
      final filteredRestaurants = allRestaurants.where((restaurant) {
        // Check city filter
        if (city != null && city.isNotEmpty) {
          final restaurantCity =
              restaurant['address']?.toString().toLowerCase() ?? '';
          if (!restaurantCity.contains(city.toLowerCase())) {
            return false;
          }
        }

        // Check country filter
        if (country != null && country.isNotEmpty) {
          final restaurantCountry =
              restaurant['country']?.toString().toLowerCase() ?? '';
          if (!restaurantCountry.contains(country.toLowerCase())) {
            return false;
          }
        }

        // Check name filter
        if (name != null && name.isNotEmpty) {
          final restaurantName =
              restaurant['name']?.toString().toLowerCase() ?? '';
          if (!restaurantName.contains(name.toLowerCase())) {
            return false;
          }
        }

        // Check category filter
        if (category != null && category.isNotEmpty && category != "All") {
          final restaurantCategories = restaurant['categories'] ?? [];
          // Handle both String and List cases
          if (restaurantCategories is String) {
            if (!restaurantCategories
                .toLowerCase()
                .contains(category.toLowerCase())) {
              return false;
            }
          } else if (restaurantCategories is List) {
            bool categoryFound = false;
            for (var cat in restaurantCategories) {
              if (cat.toString().toLowerCase() == category.toLowerCase()) {
                categoryFound = true;
                break;
              }
            }
            if (!categoryFound) return false;
          }
        }

        // Check rating filter
        if (minRating != null) {
          final rating = (restaurant['rating'] as num?)?.toDouble() ?? 0.0;
          if (rating < minRating) {
            return false;
          }
        }

        // Check price filter
        if (maxPrice != null) {
          final price = (restaurant['price_level'] as num?)?.toDouble() ?? 0.0;
          if (price > maxPrice) {
            return false;
          }
        }

        // Restaurant passed all filters
        return true;
      }).toList();

      // Apply limit if specified
      final results = limit != null && limit < filteredRestaurants.length
          ? filteredRestaurants.take(limit).toList()
          : filteredRestaurants;

      // Return single restaurant if there's exactly one match
      if (results.length == 1 && (name != null && name.isNotEmpty)) {
        return results.first;
      }

      // Otherwise return the list
      return results;
    } catch (error) {
      throw Exception('Error filtering restaurants: $error');
    }
  }

// Additional helper method to fetch a restaurant by exact ID
  Future<Map<String, dynamic>?> getRestaurantById(String id) async {
    try {
      final allRestaurants = await _fetchRestaurants();

      final restaurant = allRestaurants.firstWhere(
        (r) => r['id'].toString() == id,
        orElse: () => <String, dynamic>{},
      );

      return restaurant.isEmpty ? null : restaurant;
    } catch (error) {
      throw Exception('Error fetching restaurant by ID: $error');
    }
  }

  // Add this method to RestaurantsNotifier
  void updateFilteredResults(List<Map<String, dynamic>> filtered) {
    state = AsyncData(filtered);
  }
}
