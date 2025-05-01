import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
part 'cities_provider.g.dart';

// The chosen city provider
final chosenCityProvider = StateNotifierProvider<ChosenCityNotifier, String>(
  (ref) => ChosenCityNotifier(),
);

class ChosenCityNotifier extends StateNotifier<String> {
  static const String _cityPreferenceKey = 'chosen_city';

  ChosenCityNotifier() : super('Choose your city') {
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_cityPreferenceKey);
    if (savedCity != null) {
      state = savedCity;
    }
  }

  Future<void> updateCity(String city) async {
    if (city == state) return;

    state = city;

    // Save city to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPreferenceKey, city);
  }
}

// Using the @riverpod annotation for CitiesNotifier
@Riverpod(keepAlive: true)
class CitiesNotifier extends _$CitiesNotifier {
  PostgrestList? _cachedData;
  static const String _cacheKey = 'cities_cache';

  // Helper function to de-duplicate cities based on name
  PostgrestList _deduplicateCities(PostgrestList cities) {
    final seenNames = <String>{};
    final uniqueCities = cities.where((city) {
      final name = city['name'] as String?;
      if (name != null && seenNames.add(name)) {
        return true; // Keep it if the name is new
      }
      return false; // Discard if name is null or already seen
    }).toList();
    return PostgrestList.from(uniqueCities);
  }

  @override
  Future<PostgrestList> build() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final uniqueCities =
            _deduplicateCities(PostgrestList.from(decoded)); // De-duplicate
        _cachedData = uniqueCities;
        print("CitiesNotifier: Returning data from SharedPreferences");
        return _cachedData!;
      } catch (e) {
        print("CitiesNotifier: Error parsing cached data: $e");
        // Continue to fetch from API if parsing fails
      }
    }

    try {
      final citiesData = await Supabase.instance.client
          .from('cities')
          .select()
          .order('name', ascending: true);

      final uniqueCities = _deduplicateCities(citiesData); // De-duplicate

      print("CitiesNotifier: Cities data fetched successfully.");
      try {
        await prefs.setString(
            _cacheKey, jsonEncode(uniqueCities)); // Cache unique list
        print("CitiesNotifier: Data saved to SharedPreferences");
      } catch (e) {
        print("CitiesNotifier: Error saving to SharedPreferences: $e");
      }
      _cachedData = uniqueCities;
      return uniqueCities;
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

  Future<void> refreshCities() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();

      final citiesData = await Supabase.instance.client
          .from('cities')
          .select()
          .order('name', ascending: true);

      final uniqueCities = _deduplicateCities(citiesData); // De-duplicate

      await prefs.setString(
          _cacheKey, jsonEncode(uniqueCities)); // Cache unique list
      print("CitiesNotifier: Refreshed and cached cities data");

      _cachedData = uniqueCities;
      state = AsyncData(uniqueCities);
    } catch (error) {
      print("CitiesNotifier: Failed to refresh cities: $error");
      state = AsyncError(error, StackTrace.current);
    }
  }
}

extension on PostgrestMap {}
