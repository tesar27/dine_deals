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
}
