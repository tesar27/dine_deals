// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$themeDataHash() => r'c401405a388c1d439f50e7ed3292471a6252de27';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Convenient provider to get the current theme data
///
/// Copied from [themeData].
@ProviderFor(themeData)
const themeDataProvider = ThemeDataFamily();

/// Convenient provider to get the current theme data
///
/// Copied from [themeData].
class ThemeDataFamily extends Family<ThemeData> {
  /// Convenient provider to get the current theme data
  ///
  /// Copied from [themeData].
  const ThemeDataFamily();

  /// Convenient provider to get the current theme data
  ///
  /// Copied from [themeData].
  ThemeDataProvider call(
    Brightness brightness,
  ) {
    return ThemeDataProvider(
      brightness,
    );
  }

  @override
  ThemeDataProvider getProviderOverride(
    covariant ThemeDataProvider provider,
  ) {
    return call(
      provider.brightness,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'themeDataProvider';
}

/// Convenient provider to get the current theme data
///
/// Copied from [themeData].
class ThemeDataProvider extends AutoDisposeProvider<ThemeData> {
  /// Convenient provider to get the current theme data
  ///
  /// Copied from [themeData].
  ThemeDataProvider(
    Brightness brightness,
  ) : this._internal(
          (ref) => themeData(
            ref as ThemeDataRef,
            brightness,
          ),
          from: themeDataProvider,
          name: r'themeDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$themeDataHash,
          dependencies: ThemeDataFamily._dependencies,
          allTransitiveDependencies: ThemeDataFamily._allTransitiveDependencies,
          brightness: brightness,
        );

  ThemeDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.brightness,
  }) : super.internal();

  final Brightness brightness;

  @override
  Override overrideWith(
    ThemeData Function(ThemeDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ThemeDataProvider._internal(
        (ref) => create(ref as ThemeDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        brightness: brightness,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<ThemeData> createElement() {
    return _ThemeDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ThemeDataProvider && other.brightness == brightness;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, brightness.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ThemeDataRef on AutoDisposeProviderRef<ThemeData> {
  /// The parameter `brightness` of this provider.
  Brightness get brightness;
}

class _ThemeDataProviderElement extends AutoDisposeProviderElement<ThemeData>
    with ThemeDataRef {
  _ThemeDataProviderElement(super.provider);

  @override
  Brightness get brightness => (origin as ThemeDataProvider).brightness;
}

String _$themeNotifierHash() => r'22bed309e08f490eb0e125f38e6eb2e596b2d3ca';

/// Theme provider that manages the app's theme state
///
/// Copied from [ThemeNotifier].
@ProviderFor(ThemeNotifier)
final themeNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ThemeNotifier, ThemeMode>.internal(
  ThemeNotifier.new,
  name: r'themeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeNotifier = AutoDisposeAsyncNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
