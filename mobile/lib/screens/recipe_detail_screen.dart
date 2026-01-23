import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_config.dart';
import 'package:mobile/providers/recipes_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl, String? thumbnailUrl) async {
    if (_isVideoInitialized) return;

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: thumbnailUrl != null
            ? Center(
                child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : null,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              "Error reproducción: $errorMessage",
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Añadir Etiqueta"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Ej: Postre, Italiano"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Añadir"),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty) {
      try {
        final dio = Dio();
        await dio.post('${AppConfig.apiBaseUrl}/api/recipes/${widget.recipeId}/tags', data: {'name': tag});
        ref.invalidate(recipeDetailProvider(widget.recipeId));
        ref.invalidate(recipesListProvider);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _deleteRecipe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Receta"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = Dio();
        await dio.delete('${AppConfig.apiBaseUrl}/api/recipes/${widget.recipeId}');
        // Invalidate list AND navigate back
        ref.invalidate(recipesListProvider);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      body: recipeAsync.when(
        data: (recipe) {
          if (!_isVideoInitialized) {
             final fullUrl = recipe.fullVideoUrl;
             _initializeVideo(fullUrl, recipe.fullThumbnailUrl);
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteRecipe,
                    tooltip: "Eliminar receta",
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _isVideoInitialized && _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : Container(
                          color: Colors.black,
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 20, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            recipe.cookingTime.isEmpty ? "Tiempo N/A" : recipe.cookingTime,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                           Text(
                            "Fuente: ${recipe.source}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
                      const Divider(height: 24),

                      // Tags Section
                      Row(
                        children: [
                          Text("Etiquetas", style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                            onPressed: _addTag,
                            tooltip: "Añadir etiqueta",
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: recipe.tags.map((tag) => Chip(label: Text(tag.name))).toList(),
                      ),

                      const Divider(height: 32),
                      
                      Text("Ingredientes", style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ...recipe.ingredients.map((ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text("${ing.quantity} ${ing.item}", style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      )).toList(),
                      
                      const Divider(height: 32),
                      Text("Pasos", style: Theme.of(context).textTheme.titleLarge),
                       const SizedBox(height: 8),
                      ...recipe.steps.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.orange.shade100,
                              child: Text(
                                "${entry.key + 1}",
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value.text, style: const TextStyle(fontSize: 16, height: 1.4))),
                          ],
                        ),
                      )).toList(),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
