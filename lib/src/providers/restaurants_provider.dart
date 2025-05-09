import 'dart:convert';
import 'dart:io';
import 'package:dine_deals/src/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'restaurants_provider.g.dart';

@riverpod
class RestaurantsNotifier extends _$RestaurantsNotifier {
  static const String _cacheKey = 'places_cache';
  static const String _cacheTimestampKey = 'places_cache_timestamp';
  static const int _cacheDurationMinutes = 15; // Cache expires after 15 minutes

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return fetchRestaurants();
  }

  // Fetch the list of restaurants from Supabase.instance.client with improved caching
  Future<List<Map<String, dynamic>>> fetchRestaurants(
      {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedTimestampStr = prefs.getString(_cacheTimestampKey);

    // Only use cache if not forcing refresh and cache exists
    if (!forceRefresh && cachedTimestampStr != null) {
      final cachedTimestamp = int.parse(cachedTimestampStr);
      final cacheAge = now - cachedTimestamp;
      final cacheExpired = cacheAge > (_cacheDurationMinutes * 60 * 1000);

      if (!cacheExpired) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            print(
                "RestaurantsNotifier: Returning data from cache (age: ${(cacheAge / 60000).toStringAsFixed(1)} minutes)");
            return decoded.cast<Map<String, dynamic>>();
          } catch (e) {
            print("RestaurantsNotifier: Error parsing cached data: $e");
            // Continue to fetch from API if parsing fails
          }
        }
      } else {
        print("RestaurantsNotifier: Cache expired, fetching fresh data");
      }
    } else if (forceRefresh) {
      print("RestaurantsNotifier: Forced refresh requested");
    }

    try {
      print(
          "RestaurantsNotifier: Fetching restaurants from Supabase.instance.client");
      final placesData = await Supabase.instance.client
          .from('restaurants')
          .select()
          .order('name', ascending: true);

      // Convert to List<Map<String, dynamic>>
      final typedData =
          (placesData as List<dynamic>).cast<Map<String, dynamic>>();

      // Cache the fresh data
      try {
        await prefs.setString(_cacheKey, jsonEncode(typedData));
        await prefs.setString(_cacheTimestampKey, now.toString());
        print("RestaurantsNotifier: Data saved to SharedPreferences");
      } catch (e) {
        print("RestaurantsNotifier: Error saving to SharedPreferences: $e");
      }

      return typedData;
    } catch (error) {
      print("RestaurantsNotifier: Error fetching data: $error");

      // Try to return cached data even if expired as a fallback
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          print("RestaurantsNotifier: Returning expired cache as fallback");
          return decoded.cast<Map<String, dynamic>>();
        } catch (e) {
          print("RestaurantsNotifier: Error parsing fallback cached data: $e");
        }
      }

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

      // Step 2: Save the new place in Supabase.instance.client
      await Supabase.instance.client.from('restaurants').insert({
        'name': name,
        'address': address,
        'latitude': coordinates['lat'],
        'longitude': coordinates['lng'],
      });

      // Step 3: Force refresh the list of restaurants with fresh data
      await fetchRestaurants(forceRefresh: true);

      // Step 4: Invalidate the provider to trigger UI update
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
      final allRestaurants = await fetchRestaurants();

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
      final allRestaurants = await fetchRestaurants();

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

  // Check if a restaurant with the same name and address already exists
  Future<bool> checkPlaceExists(
      {required String name, required String address}) async {
    try {
      // Query based on both name and address
      final result = await Supabase.instance.client
          .from('restaurants')
          .select()
          .ilike('name', name)
          .ilike('address', address);

      // Return true if any results were found
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking for existing place: $e');
      return false; // In case of error, assume it doesn't exist
    }
  }

  // Upload an image to Supabase.instance.client storage
  Future<String?> uploadImage(File imageFile,
      {required int restaurantId}) async {
    try {
      // Generate a unique filename with restaurant ID and timestamp
      final String fileName =
          'restaurant_${restaurantId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload file to Supabase.instance.client storage
      await Supabase.instance.client.storage
          .from('pictures')
          .upload(fileName, imageFile);

      // Get the public URL for the uploaded file
      final String imageUrl = Supabase.instance.client.storage
          .from('pictures')
          .getPublicUrl(fileName);

      debugPrint('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw 'Failed to upload image: $e';
    }
  }

  // Update restaurant image URL in the database
  Future<void> updateRestaurantImage(int restaurantId, String imageUrl) async {
    try {
      // Update the restaurant record in the database
      await Supabase.instance.client
          .from('restaurants')
          .update({'imageUrl': imageUrl}).eq('id', restaurantId);

      debugPrint('Restaurant image URL updated in database');

      // Update the state to reflect the change without needing a full refresh
      if (state.hasValue && state.value != null) {
        final updatedList = state.value!.map((restaurant) {
          if (restaurant['id'] == restaurantId) {
            return {...restaurant, 'imageUrl': imageUrl};
          }
          return restaurant;
        }).toList();

        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      debugPrint('Error updating restaurant image in database: $e');
      throw 'Failed to update restaurant image in database: $e';
    }
  }
}
