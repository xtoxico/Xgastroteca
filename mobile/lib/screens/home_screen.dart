import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/providers/recipes_provider.dart';
import 'package:mobile/widgets/add_recipe_dialog.dart';
import 'package:transparent_image/transparent_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchValuesChanged(String value) {
     // rudimentary debounce can be added here
     // for now update state on submit or immediate
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesListProvider(search: _searchQuery));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddRecipeDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Xgastroteca'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar receta (ej: Tiramisú)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
        ),
      ),
      body: recipesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(child: Text("No hay recetas. ¡Añade una!"));
          }
          return RefreshIndicator(
            onRefresh: () async {
               ref.invalidate(recipesListProvider);
            },
            child: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      context.push('/recipe/${recipe.id}');
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video Thumbnail (Placeholder or generated)
                        // If we had image thumbnails, we'd use them. 
                        // For now show a generic placeholder or color
                        // Video Thumbnail (or placeholder)
                        recipe.fullThumbnailUrl != null
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  FadeInImage.memoryNetwork(
                                    placeholder: kTransparentImage,
                                    image: recipe.fullThumbnailUrl!,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 180,
                                        width: double.infinity,
                                        color: Colors.grey.shade300,
                                        child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
                                      );
                                    },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, size: 50, color: Colors.white),
                                  ),
                                ],
                              )
                            : Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recipe.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: recipe.tags.take(3).map((tag) => Chip(
                                  label: Text(tag.name),
                                  backgroundColor: Colors.orange.shade50,
                                  labelStyle: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                                )).toList(),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
