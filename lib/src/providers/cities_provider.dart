import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

part 'cities_provider.g.dart';

@Riverpod(keepAlive: true)
class CitiesNotifier extends _$CitiesNotifier {
  PostgrestList? _cachedData;
  static const String _cacheKey = 'cities_cache';

  @override
  Future<PostgrestList> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _cachedData = PostgrestList.from(decoded);
        print("CitiesNotifier: Returning data from SharedPreferences");
        return _cachedData!;
      } catch (e) {
        print("CitiesNotifier: Error parsing cached data: $e");
        // Continue to fetch from API if parsing fails
      }
    }

    try {
      // .single() returns the Map directly on success or throws on error
      final citiesData = await Supabase.instance.client
          .from('cities')
          .select()
          .order('name',
              ascending:
                  true); // Optional: Order by name // Selects all columns by default
      // Returns PostgrestMap (Map<String, dynamic>) or throws PostgrestException

      print(
          "CitiesNotifier: Cities data fetched successfully."); // Optional: for debugging
      // If we reach here, the query was successful and citiesData is the Map
      // Save to SharedPreferences
      try {
        await prefs.setString(_cacheKey, jsonEncode(citiesData));
        print("CitiesNotifier: Data saved to SharedPreferences");
      } catch (e) {
        print("CitiesNotifier: Error saving to SharedPreferences: $e");
      }
      _cachedData = citiesData;
      return citiesData; // Type is already Map<String, dynamic>
    } on PostgrestException catch (error) {
      // Handle specific Supabase errors
      print(
          "CitiesNotifier: Failed to fetch user data. Supabase error: ${error.message}");
      // Re-throw the error or a custom exception so Riverpod can handle the error state
      // This allows AsyncValue.error() state in the UI
      throw Exception(
          'Failed to load user profile: ${error.message}'); // Or rethrow error;
    } catch (error) {
      // Catch any other unexpected errors
      print("CitiesNotifier: An unexpected error occurred: $error");
      throw Exception('An unexpected error occurred while fetching user data.');
    }
  }
}

extension on PostgrestMap {}
