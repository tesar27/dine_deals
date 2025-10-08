// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restaurantDataHash() => r'c85871fab04afccf233f9a346501442321478961';

/// See also [RestaurantData].
@ProviderFor(RestaurantData)
final restaurantDataProvider = AutoDisposeAsyncNotifierProvider<RestaurantData,
    List<Map<String, dynamic>>>.internal(
  RestaurantData.new,
  name: r'restaurantDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RestaurantData = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
String _$cityDataHash() => r'7d1972eacda38df3612540a07d3ad98c15757bef';

/// See also [CityData].
@ProviderFor(CityData)
final cityDataProvider =
    AutoDisposeAsyncNotifierProvider<CityData, List<String>>.internal(
  CityData.new,
  name: r'cityDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cityDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CityData = AutoDisposeAsyncNotifier<List<String>>;
String _$dealsDataHash() => r'f2b4f171bc7eca39c25e6315735e7fc9f93cafc9';

/// See also [DealsData].
@ProviderFor(DealsData)
final dealsDataProvider = AutoDisposeAsyncNotifierProvider<DealsData,
    List<Map<String, dynamic>>>.internal(
  DealsData.new,
  name: r'dealsDataProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dealsDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DealsData = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
