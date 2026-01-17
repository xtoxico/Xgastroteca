import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/models/recipe.dart';

part 'recipes_provider.g.dart';

// --- Repository ---

class RecipesRepository {
  final Dio _dio;

  RecipesRepository(this._dio);

  Future<List<Recipe>> getRecipes({int page = 1, int limit = 12, String search = ''}) async {
    try {
      final response = await _dio.get('/api/recipes', queryParameters: {
        'page': page,
        'limit': limit,
        'search': search,
      });

      // API returns { "data": [...], "meta": {...} }
      final data = response.data['data'] as List<dynamic>;
      return data.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }

  Future<Recipe> getRecipe(String id) async {
    try {
      final response = await _dio.get('/api/recipes/$id');
      return Recipe.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load recipe detail: $e');
    }
  }

  Future<Recipe> addRecipe(String url) async {
    try {
      final response = await _dio.post('/api/process', data: {'url': url});
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
         // Handle AI errors or duplicates
         final error = e.response!.data['error'] ?? 'Unknown error';
         final code = e.response!.data['code'];
         
         // If it's a conflict (409), generally we might handle it as success or specific error, 
         // but backend returns the recipe in 200 OK now for duplicates.
         // If "not_a_recipe", we propagate exception.
         throw Exception(error);
      }
      throw Exception('Failed to add recipe: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }
}

@riverpod
RecipesRepository recipesRepository(RecipesRepositoryRef ref) {
  final dio = ref.watch(apiClientProvider);
  return RecipesRepository(dio);
}

// --- Providers ---

@riverpod
Future<List<Recipe>> recipesList(RecipesListRef ref, {int page = 1, String search = ''}) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getRecipes(page: page, search: search);
}

@riverpod
Future<Recipe> recipeDetail(RecipeDetailRef ref, String id) async {
  final repository = ref.watch(recipesRepositoryProvider);
  return repository.getRecipe(id);
}

// --- Processor Notifier ---

@riverpod
class RecipeProcessor extends _$RecipeProcessor {
  @override
  FutureOr<Recipe?> build() {
    return null; // Initial state: no recipe processed yet
  }

  Future<void> processUrl(String url) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(recipesRepositoryProvider);
      final recipe = await repository.addRecipe(url);
      
      state = AsyncData(recipe);
      
      // Refresh the list to show the new recipe
      ref.invalidate(recipesListProvider); 
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
