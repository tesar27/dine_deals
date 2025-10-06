import 'dart:convert';
import 'package:dine_deals/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'app_data_provider.g.dart';

// =============================================================================
// RESTAURANT PROVIDER - Consolidated from restaurants_provider and places_provider
// =============================================================================

@riverpod
class RestaurantData extends _$RestaurantData {
  static const String _cacheKey = 'restaurants_cache';
  static const String _cacheTimestampKey = 'restaurants_cache_timestamp';
  static const int _cacheDurationMinutes = 15;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return fetchRestaurants();
  }

  Future<List<Map<String, dynamic>>> fetchRestaurants(
      {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedTimestampStr = prefs.getString(_cacheTimestampKey);

    // Check cache validity
    if (!forceRefresh && cachedTimestampStr != null) {
      final cachedTimestamp = int.parse(cachedTimestampStr);
      final cacheAge = now - cachedTimestamp;
      final cacheExpired = cacheAge > (_cacheDurationMinutes * 60 * 1000);

      if (!cacheExpired) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded.cast<Map<String, dynamic>>();
          } catch (e) {
            debugPrint("Error parsing cached restaurant data: $e");
          }
        }
      }
    }

    try {
      final data = await Supabase.instance.client
          .from('restaurants')
          .select()
          .order('name', ascending: true);

      final typedData = (data as List<dynamic>).cast<Map<String, dynamic>>();

      // Cache the fresh data
      try {
        await prefs.setString(_cacheKey, jsonEncode(typedData));
        await prefs.setString(_cacheTimestampKey, now.toString());
      } catch (e) {
        debugPrint("Error saving restaurant cache: $e");
      }

      return typedData;
    } catch (error) {
      // Fallback to expired cache if available
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded.cast<Map<String, dynamic>>();
        } catch (e) {
          debugPrint("Error parsing fallback cached data: $e");
        }
      }
      throw Exception('Failed to fetch restaurants: $error');
    }
  }

  Future<void> addRestaurant({
    required String name,
    required String address,
  }) async {
    try {
      final coordinates = await _getCoordinatesFromAddress(address);

      await Supabase.instance.client.from('restaurants').insert({
        'name': name,
        'address': address,
        'latitude': coordinates['lat'],
        'longitude': coordinates['lng'],
      });

      await fetchRestaurants(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to add restaurant: $error');
    }
  }

  Future<void> updateRestaurant({
    required int id,
    String? name,
    String? address,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) {
        updates['address'] = address;
        final coordinates = await _getCoordinatesFromAddress(address);
        updates['latitude'] = coordinates['lat'];
        updates['longitude'] = coordinates['lng'];
      }

      await Supabase.instance.client
          .from('restaurants')
          .update(updates)
          .eq('id', id);

      await fetchRestaurants(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to update restaurant: $error');
    }
  }

  Future<void> deleteRestaurant(int id) async {
    try {
      await Supabase.instance.client.from('restaurants').delete().eq('id', id);

      await fetchRestaurants(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to delete restaurant: $error');
    }
  }

  List<Map<String, dynamic>> getFilteredRestaurants(String query) {
    final current = state.value ?? [];
    if (query.isEmpty) return current;
    return current.where((restaurant) {
      final name = restaurant['name']?.toString().toLowerCase() ?? '';
      final address = restaurant['address']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || address.contains(searchQuery);
    }).toList();
  }

  void updateFilteredResults(String query) {
    // This method triggers a rebuild with filtered results
    ref.invalidateSelf();
  }

  Future<void> uploadImage(String imagePath) async {
    // Placeholder for image upload functionality
    throw UnimplementedError('Image upload not implemented yet');
  }

  Future<void> updateRestaurantImage(int restaurantId, String imageUrl) async {
    // Placeholder for updating restaurant image
    throw UnimplementedError('Restaurant image update not implemented yet');
  }

  Future<bool> checkPlaceExists(String name) async {
    try {
      final data = await Supabase.instance.client
          .from('restaurants')
          .select('id')
          .eq('name', name)
          .limit(1);
      return data.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  Future<void> addPlace({required String name, required String address}) async {
    await addRestaurant(name: name, address: address);
  }

  Future<Map<String, double>> _getCoordinatesFromAddress(String address) async {
    final apiKey = Config.opencageApi;
    final url =
        'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(address)}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'] != null && data['results'].isNotEmpty) {
        final geometry = data['results'][0]['geometry'];
        return {
          'lat': geometry['lat'].toDouble(),
          'lng': geometry['lng'].toDouble(),
        };
      }
    }
    throw Exception('Failed to get coordinates for address: $address');
  }
}

// =============================================================================
// CITY PROVIDER - Enhanced with better state management
// =============================================================================

@riverpod
class CityData extends _$CityData {
  static const String _cacheKey = 'cities_cache';
  static const String _chosenCityKey = 'chosen_city';

  @override
  Future<List<String>> build() async {
    return fetchCities();
  }

  Future<List<String>> fetchCities() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        return decoded.cast<String>();
      } catch (e) {
        debugPrint("Error parsing cached cities: $e");
      }
    }

    try {
      final data = await Supabase.instance.client
          .from('cities')
          .select('name')
          .order('name', ascending: true);

      final cities = (data as List<dynamic>)
          .map((city) => city['name'] as String)
          .toList();

      // Cache the cities
      await prefs.setString(_cacheKey, jsonEncode(cities));
      return cities;
    } catch (error) {
      throw Exception('Failed to fetch cities: $error');
    }
  }

  Future<String> getChosenCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chosenCityKey) ?? 'Choose your city';
  }

  Future<void> setChosenCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chosenCityKey, city);
  }

  Future<void> refreshCities() async {
    ref.invalidateSelf();
  }
}

// =============================================================================
// DEALS PROVIDER - Consolidated and optimized
// =============================================================================

@riverpod
class DealsData extends _$DealsData {
  static const String _cacheKey = 'deals_cache';
  static const String _cacheTimestampKey = 'deals_cache_timestamp';
  static const int _cacheDurationMinutes = 10;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return fetchDeals();
  }

  Future<List<Map<String, dynamic>>> fetchDeals(
      {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cachedTimestampStr = prefs.getString(_cacheTimestampKey);

    // Check cache validity
    if (!forceRefresh && cachedTimestampStr != null) {
      final cachedTimestamp = int.parse(cachedTimestampStr);
      final cacheAge = now - cachedTimestamp;
      final cacheExpired = cacheAge > (_cacheDurationMinutes * 60 * 1000);

      if (!cacheExpired) {
        final cachedJson = prefs.getString(_cacheKey);
        if (cachedJson != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedJson);
            return decoded.cast<Map<String, dynamic>>();
          } catch (e) {
            debugPrint("Error parsing cached deals: $e");
          }
        }
      }
    }

    try {
      final data = await Supabase.instance.client
          .from('deals')
          .select('*, restaurants(id, name, address)')
          .order('created_at', ascending: false);

      final typedData = (data as List<dynamic>).cast<Map<String, dynamic>>();

      // Cache the fresh data
      try {
        await prefs.setString(_cacheKey, jsonEncode(typedData));
        await prefs.setString(_cacheTimestampKey, now.toString());
      } catch (e) {
        debugPrint("Error saving deals cache: $e");
      }

      return typedData;
    } catch (error) {
      throw Exception('Failed to fetch deals: $error');
    }
  }

  Future<void> addDeal({
    required String title,
    required String description,
    required int restaurantId,
    required double discountPercentage,
    DateTime? validUntil,
  }) async {
    try {
      await Supabase.instance.client.from('deals').insert({
        'title': title,
        'description': description,
        'restaurant_id': restaurantId,
        'discount_percentage': discountPercentage,
        'valid_until': validUntil?.toIso8601String(),
        'is_active': true,
      });

      await fetchDeals(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to add deal: $error');
    }
  }

  List<Map<String, dynamic>> getDealsForRestaurant(int restaurantId) {
    final current = state.value ?? [];
    return current.where((deal) => deal['restaurant_id'] == restaurantId).toList();
  }

  Future<void> deleteDeal(int dealId) async {
    try {
      await Supabase.instance.client.from('deals').delete().eq('id', dealId);
      await fetchDeals(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to delete deal: $error');
    }
  }
}

// =============================================================================
// CHOSEN CITY PROVIDER - For managing selected city
// =============================================================================

// Simple StateProvider for chosen city
final chosenCityProvider = StateProvider<String>((ref) => 'Choose your city');
