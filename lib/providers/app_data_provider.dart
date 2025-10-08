import 'dart:convert';
import 'dart:io';
import 'package:dine_deals/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dine_deals/models/restaurant_model.dart';
import 'package:dine_deals/models/deal_model.dart';
import 'package:dine_deals/models/city_model.dart';

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

  /// Return typed Restaurant objects mapped from the cached/fresh maps.
  Future<List<Restaurant>> fetchRestaurantsTyped({bool forceRefresh = false}) async {
    final maps = await fetchRestaurants(forceRefresh: forceRefresh);
    return maps.map((m) => Restaurant.fromMap(m)).toList();
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

  

  /// Returns a list of restaurants filtered by optional named parameters.
  /// Supports filtering by name, city, country or category. If no filters are
  /// provided, returns all restaurants.
  Future<List<Map<String, dynamic>>> getFilteredRestaurants({
    String? name,
    String? city,
    String? country,
    String? category,
  }) async {
    final all = await fetchRestaurants();

    Iterable<Map<String, dynamic>> results = all;

    if (name != null && name.isNotEmpty) {
      final q = name.toLowerCase();
      results = results.where((r) {
        final n = r['name']?.toString().toLowerCase() ?? '';
        final a = r['address']?.toString().toLowerCase() ?? '';
        return n.contains(q) || a.contains(q);
      });
    }

    if (city != null && city.isNotEmpty) {
      final c = city.toLowerCase();
      results = results.where((r) {
        final addr = r['address']?.toString().toLowerCase() ?? '';
        final cityField = r['city']?.toString().toLowerCase() ?? '';
        return addr.contains(c) || cityField.contains(c);
      });
    }

    if (country != null && country.isNotEmpty) {
      final c = country.toLowerCase();
      results = results.where((r) {
        final countryField = r['country']?.toString().toLowerCase() ?? '';
        return countryField.contains(c);
      });
    }

    if (category != null && category.isNotEmpty) {
      final cat = category.toLowerCase();
      results = results.where((r) {
        final categories = r['categories'];
        if (categories == null) return false;
        if (categories is String) {
          return categories.toLowerCase().contains(cat);
        }
        if (categories is List) {
          return categories.map((e) => e.toString().toLowerCase()).contains(cat);
        }
        return false;
      });
    }

    return results.toList();
  }

  void updateFilteredResults(dynamic _filtered) {
    // Accept either a search query or a pre-filtered list and trigger a refresh
    ref.invalidateSelf();
  }

  Future<String?> uploadImage(File file, {required dynamic restaurantId}) async {
    try {
  const bucket = 'pictures';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';

      final storage = Supabase.instance.client.storage;
      await storage.from(bucket).upload(fileName, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));

      final publicUrl = storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> updateRestaurantImage(int restaurantId, String imageUrl) async {
    // Placeholder for updating restaurant image
    throw UnimplementedError('Restaurant image update not implemented yet');
  }

  Future<bool> checkPlaceExists({required String name, String? address}) async {
    try {
  final filters = <String, Object>{'name': name};
  if (address != null && address.isNotEmpty) filters['address'] = address;
      final data = await Supabase.instance.client
          .from('restaurants')
          .select('id')
          .match(filters)
          .limit(1);
      final list = data as List<dynamic>;
      return list.isNotEmpty;
    } catch (error) {
      debugPrint('Error checking place exists: $error');
      return false;
    }
  }

  Future<void> addPlace({required String name, required String address}) async {
    await addRestaurant(name: name, address: address);
  }

  /// Typed helper to get filtered Restaurant model instances.
  Future<List<Restaurant>> getFilteredRestaurantsTyped({
    String? name,
    String? city,
    String? country,
    String? category,
  }) async {
    final maps = await getFilteredRestaurants(
      name: name,
      city: city,
      country: country,
      category: category,
    );
    return maps.map((m) => Restaurant.fromMap(m)).toList();
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

  /// Fetch full city records (including latitude/longitude) for callers that
  /// require geographic data. This is intentionally a separate API so the
  /// generated provider continues to return a lightweight List<String>.
  Future<List<Map<String, dynamic>>> fetchCityRecords() async {
    try {
      final data = await Supabase.instance.client
          .from('cities')
          .select('id, name, latitude, longitude')
          .order('name', ascending: true);
      return (data as List<dynamic>)
          .map((city) => {
                'id': city['id'],
                'name': city['name'],
                'latitude': city['latitude'],
                'longitude': city['longitude'],
              })
          .toList();
    } catch (e) {
      debugPrint('Error fetching city records: $e');
      return [];
    }
  }

  /// Typed helper returning City model instances for callers that need full city data
  Future<List<City>> fetchCityRecordsTyped() async {
    final maps = await fetchCityRecords();
    return maps.map((m) => City.fromMap(m)).toList();
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

  /// Typed helper to get Deal model instances from the cached/fresh data
  Future<List<Deal>> fetchDealsTyped({bool forceRefresh = false}) async {
    final maps = await fetchDeals(forceRefresh: forceRefresh);
    return maps.map((m) => Deal.fromMap(m)).toList();
  }

  Future<void> addDeal({
    String? title,
    String? name,
    required String description,
    required dynamic restaurantId,
    double? discountPercentage,
    double? savings,
    DateTime? validUntil,
  }) async {
    try {
      final resolvedTitle = title ?? name ?? 'Special Offer';
      final resolvedRestaurantId = restaurantId is String
          ? int.tryParse(restaurantId) ?? 0
          : (restaurantId as int);
      final resolvedDiscount = discountPercentage ?? (savings ?? 0.0);

      await Supabase.instance.client.from('deals').insert({
        'title': resolvedTitle,
        'description': description,
        'restaurant_id': resolvedRestaurantId,
        'discount_percentage': resolvedDiscount,
        'valid_until': validUntil?.toIso8601String(),
        'is_active': true,
      });

      await fetchDeals(forceRefresh: true);
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to add deal: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getDealsForRestaurant(dynamic restaurantId) async {
    final current = state.value ?? [];
    int id;
    if (restaurantId is String) {
      id = int.tryParse(restaurantId) ?? -1;
    } else if (restaurantId is int) {
      id = restaurantId;
    } else {
      id = -1;
    }
    return current.where((deal) => deal['restaurant_id'] == id).toList().cast<Map<String, dynamic>>();
  }

  /// Typed version of getDealsForRestaurant
  Future<List<Deal>> getDealsForRestaurantTyped(dynamic restaurantId) async {
    final maps = await getDealsForRestaurant(restaurantId);
    return maps.map((m) => Deal.fromMap(m)).toList();
  }

  Future<void> deleteDeal(dynamic dealId) async {
    try {
      final id = dealId is String ? int.tryParse(dealId) ?? -1 : (dealId as int);
      await Supabase.instance.client.from('deals').delete().eq('id', id);
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

// Provide a convenience extension so UI code can call
// ref.read(chosenCityProvider.notifier).updateCity('City')
// without needing to change all call sites.
extension ChosenCityControllerExt on StateController<String> {
  void updateCity(String city) => state = city;
}
