// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nearbyPOIsHash() => r'58e5d316bdb33ca74510305740795185045a7c79';

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

/// See also [nearbyPOIs].
@ProviderFor(nearbyPOIs)
const nearbyPOIsProvider = NearbyPOIsFamily();

/// See also [nearbyPOIs].
class NearbyPOIsFamily extends Family<AsyncValue<List<POI>>> {
  /// See also [nearbyPOIs].
  const NearbyPOIsFamily();

  /// See also [nearbyPOIs].
  NearbyPOIsProvider call({
    POIType? type,
  }) {
    return NearbyPOIsProvider(
      type: type,
    );
  }

  @override
  NearbyPOIsProvider getProviderOverride(
    covariant NearbyPOIsProvider provider,
  ) {
    return call(
      type: provider.type,
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
  String? get name => r'nearbyPOIsProvider';
}

/// See also [nearbyPOIs].
class NearbyPOIsProvider extends AutoDisposeFutureProvider<List<POI>> {
  /// See also [nearbyPOIs].
  NearbyPOIsProvider({
    POIType? type,
  }) : this._internal(
          (ref) => nearbyPOIs(
            ref as NearbyPOIsRef,
            type: type,
          ),
          from: nearbyPOIsProvider,
          name: r'nearbyPOIsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nearbyPOIsHash,
          dependencies: NearbyPOIsFamily._dependencies,
          allTransitiveDependencies:
              NearbyPOIsFamily._allTransitiveDependencies,
          type: type,
        );

  NearbyPOIsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final POIType? type;

  @override
  Override overrideWith(
    FutureOr<List<POI>> Function(NearbyPOIsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NearbyPOIsProvider._internal(
        (ref) => create(ref as NearbyPOIsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<POI>> createElement() {
    return _NearbyPOIsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NearbyPOIsProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NearbyPOIsRef on AutoDisposeFutureProviderRef<List<POI>> {
  /// The parameter `type` of this provider.
  POIType? get type;
}

class _NearbyPOIsProviderElement
    extends AutoDisposeFutureProviderElement<List<POI>> with NearbyPOIsRef {
  _NearbyPOIsProviderElement(super.provider);

  @override
  POIType? get type => (origin as NearbyPOIsProvider).type;
}

String _$allPOIsHash() => r'09ce4b234f5c09ea274f2b5c9893217b41709fdd';

/// See also [allPOIs].
@ProviderFor(allPOIs)
final allPOIsProvider = AutoDisposeStreamProvider<List<POI>>.internal(
  allPOIs,
  name: r'allPOIsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPOIsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPOIsRef = AutoDisposeStreamProviderRef<List<POI>>;
String _$poiByIdHash() => r'1abbb4c5611d03bb7dfd6f36dbe958cbe1c605fa';

/// See also [poiById].
@ProviderFor(poiById)
const poiByIdProvider = PoiByIdFamily();

/// See also [poiById].
class PoiByIdFamily extends Family<AsyncValue<POI?>> {
  /// See also [poiById].
  const PoiByIdFamily();

  /// See also [poiById].
  PoiByIdProvider call(
    String id,
  ) {
    return PoiByIdProvider(
      id,
    );
  }

  @override
  PoiByIdProvider getProviderOverride(
    covariant PoiByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'poiByIdProvider';
}

/// See also [poiById].
class PoiByIdProvider extends AutoDisposeFutureProvider<POI?> {
  /// See also [poiById].
  PoiByIdProvider(
    String id,
  ) : this._internal(
          (ref) => poiById(
            ref as PoiByIdRef,
            id,
          ),
          from: poiByIdProvider,
          name: r'poiByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$poiByIdHash,
          dependencies: PoiByIdFamily._dependencies,
          allTransitiveDependencies: PoiByIdFamily._allTransitiveDependencies,
          id: id,
        );

  PoiByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<POI?> Function(PoiByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PoiByIdProvider._internal(
        (ref) => create(ref as PoiByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<POI?> createElement() {
    return _PoiByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PoiByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PoiByIdRef on AutoDisposeFutureProviderRef<POI?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PoiByIdProviderElement extends AutoDisposeFutureProviderElement<POI?>
    with PoiByIdRef {
  _PoiByIdProviderElement(super.provider);

  @override
  String get id => (origin as PoiByIdProvider).id;
}

String _$topRatedPOIsHash() => r'876c6488c74e7c085b5dd1ddf291609551200c87';

/// See also [topRatedPOIs].
@ProviderFor(topRatedPOIs)
const topRatedPOIsProvider = TopRatedPOIsFamily();

/// See also [topRatedPOIs].
class TopRatedPOIsFamily extends Family<AsyncValue<List<POI>>> {
  /// See also [topRatedPOIs].
  const TopRatedPOIsFamily();

  /// See also [topRatedPOIs].
  TopRatedPOIsProvider call({
    required POIType type,
  }) {
    return TopRatedPOIsProvider(
      type: type,
    );
  }

  @override
  TopRatedPOIsProvider getProviderOverride(
    covariant TopRatedPOIsProvider provider,
  ) {
    return call(
      type: provider.type,
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
  String? get name => r'topRatedPOIsProvider';
}

/// See also [topRatedPOIs].
class TopRatedPOIsProvider extends AutoDisposeFutureProvider<List<POI>> {
  /// See also [topRatedPOIs].
  TopRatedPOIsProvider({
    required POIType type,
  }) : this._internal(
          (ref) => topRatedPOIs(
            ref as TopRatedPOIsRef,
            type: type,
          ),
          from: topRatedPOIsProvider,
          name: r'topRatedPOIsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$topRatedPOIsHash,
          dependencies: TopRatedPOIsFamily._dependencies,
          allTransitiveDependencies:
              TopRatedPOIsFamily._allTransitiveDependencies,
          type: type,
        );

  TopRatedPOIsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final POIType type;

  @override
  Override overrideWith(
    FutureOr<List<POI>> Function(TopRatedPOIsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TopRatedPOIsProvider._internal(
        (ref) => create(ref as TopRatedPOIsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<POI>> createElement() {
    return _TopRatedPOIsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopRatedPOIsProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopRatedPOIsRef on AutoDisposeFutureProviderRef<List<POI>> {
  /// The parameter `type` of this provider.
  POIType get type;
}

class _TopRatedPOIsProviderElement
    extends AutoDisposeFutureProviderElement<List<POI>> with TopRatedPOIsRef {
  _TopRatedPOIsProviderElement(super.provider);

  @override
  POIType get type => (origin as TopRatedPOIsProvider).type;
}

String _$pOIFilterHash() => r'e990ba9c118c74d34e19601f6e0ddc8ed2d823c1';

/// See also [POIFilter].
@ProviderFor(POIFilter)
final pOIFilterProvider =
    AutoDisposeNotifierProvider<POIFilter, POIType?>.internal(
  POIFilter.new,
  name: r'pOIFilterProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$pOIFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$POIFilter = AutoDisposeNotifier<POIType?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
