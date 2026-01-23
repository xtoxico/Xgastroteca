// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recipesRepositoryHash() => r'67f6ca5cd253cec34f990eedbc0133cd2abd451f';

/// See also [recipesRepository].
@ProviderFor(recipesRepository)
final recipesRepositoryProvider =
    AutoDisposeProvider<RecipesRepository>.internal(
      recipesRepository,
      name: r'recipesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recipesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecipesRepositoryRef = AutoDisposeProviderRef<RecipesRepository>;
String _$recipeDetailHash() => r'939f352ab346daca3661676f731da60a2fc7528c';

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

/// See also [recipeDetail].
@ProviderFor(recipeDetail)
const recipeDetailProvider = RecipeDetailFamily();

/// See also [recipeDetail].
class RecipeDetailFamily extends Family<AsyncValue<Recipe>> {
  /// See also [recipeDetail].
  const RecipeDetailFamily();

  /// See also [recipeDetail].
  RecipeDetailProvider call(String id) {
    return RecipeDetailProvider(id);
  }

  @override
  RecipeDetailProvider getProviderOverride(
    covariant RecipeDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recipeDetailProvider';
}

/// See also [recipeDetail].
class RecipeDetailProvider extends AutoDisposeFutureProvider<Recipe> {
  /// See also [recipeDetail].
  RecipeDetailProvider(String id)
    : this._internal(
        (ref) => recipeDetail(ref as RecipeDetailRef, id),
        from: recipeDetailProvider,
        name: r'recipeDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recipeDetailHash,
        dependencies: RecipeDetailFamily._dependencies,
        allTransitiveDependencies:
            RecipeDetailFamily._allTransitiveDependencies,
        id: id,
      );

  RecipeDetailProvider._internal(
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
    FutureOr<Recipe> Function(RecipeDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecipeDetailProvider._internal(
        (ref) => create(ref as RecipeDetailRef),
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
  AutoDisposeFutureProviderElement<Recipe> createElement() {
    return _RecipeDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeDetailProvider && other.id == id;
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
mixin RecipeDetailRef on AutoDisposeFutureProviderRef<Recipe> {
  /// The parameter `id` of this provider.
  String get id;
}

class _RecipeDetailProviderElement
    extends AutoDisposeFutureProviderElement<Recipe>
    with RecipeDetailRef {
  _RecipeDetailProviderElement(super.provider);

  @override
  String get id => (origin as RecipeDetailProvider).id;
}

String _$recipesListHash() => r'81642c1a23265a3c11fce068f57beecca8f0947a';

abstract class _$RecipesList
    extends BuildlessAutoDisposeAsyncNotifier<List<Recipe>> {
  late final String search;

  FutureOr<List<Recipe>> build({String search = ''});
}

/// See also [RecipesList].
@ProviderFor(RecipesList)
const recipesListProvider = RecipesListFamily();

/// See also [RecipesList].
class RecipesListFamily extends Family<AsyncValue<List<Recipe>>> {
  /// See also [RecipesList].
  const RecipesListFamily();

  /// See also [RecipesList].
  RecipesListProvider call({String search = ''}) {
    return RecipesListProvider(search: search);
  }

  @override
  RecipesListProvider getProviderOverride(
    covariant RecipesListProvider provider,
  ) {
    return call(search: provider.search);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recipesListProvider';
}

/// See also [RecipesList].
class RecipesListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<RecipesList, List<Recipe>> {
  /// See also [RecipesList].
  RecipesListProvider({String search = ''})
    : this._internal(
        () => RecipesList()..search = search,
        from: recipesListProvider,
        name: r'recipesListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recipesListHash,
        dependencies: RecipesListFamily._dependencies,
        allTransitiveDependencies: RecipesListFamily._allTransitiveDependencies,
        search: search,
      );

  RecipesListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.search,
  }) : super.internal();

  final String search;

  @override
  FutureOr<List<Recipe>> runNotifierBuild(covariant RecipesList notifier) {
    return notifier.build(search: search);
  }

  @override
  Override overrideWith(RecipesList Function() create) {
    return ProviderOverride(
      origin: this,
      override: RecipesListProvider._internal(
        () => create()..search = search,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        search: search,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RecipesList, List<Recipe>>
  createElement() {
    return _RecipesListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipesListProvider && other.search == search;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RecipesListRef on AutoDisposeAsyncNotifierProviderRef<List<Recipe>> {
  /// The parameter `search` of this provider.
  String get search;
}

class _RecipesListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RecipesList, List<Recipe>>
    with RecipesListRef {
  _RecipesListProviderElement(super.provider);

  @override
  String get search => (origin as RecipesListProvider).search;
}

String _$recipeProcessorHash() => r'c60aba4ed8e415cfa13616084a484f6497e52213';

/// See also [RecipeProcessor].
@ProviderFor(RecipeProcessor)
final recipeProcessorProvider =
    AutoDisposeAsyncNotifierProvider<RecipeProcessor, Recipe?>.internal(
      RecipeProcessor.new,
      name: r'recipeProcessorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recipeProcessorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecipeProcessor = AutoDisposeAsyncNotifier<Recipe?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
