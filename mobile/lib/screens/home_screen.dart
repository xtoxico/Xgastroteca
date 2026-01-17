import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/app_config.dart';
import 'package:mobile/models/recipe.dart';
import 'package:mobile/providers/recipes_provider.dart';
import 'package:mobile/widgets/add_recipe_dialog.dart';
import 'package:mobile/widgets/recipe_card.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();

    // Sharing Intent likely NOT supported on Web via this plugin.
    if (kIsWeb) return;

    // Listen to media share (for text/url)
    // ReceiveSharingIntent 1.6.8 uses getMediaStream for text sharing too (path contains text)
    
    // For sharing link/text while app is open
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
             _handleSharedFiles(value);
        }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // Get the media we were opened with
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
         if (value.isNotEmpty) {
             _handleSharedFiles(value);
             ReceiveSharingIntent.instance.reset();
         }
    });
  }

  void _handleSharedText(String text) {
      if (text.startsWith('http')) {
          _openAddRecipeDialog(text);
      }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
      // Check if we have a valid URL in the "path" or "thumbnail" or wherever text might be stashed
      // OR, maybe we should have used getTextStream().
      // Let's assume for a moment that for text/plain, it might be safer to try getTextStream if we were sure.
      // But let's implement validation.
      
      for (var file in files) {
          // Sometimes text is in path
          final text = file.path;
          if (text.startsWith('http')) {
              _openAddRecipeDialog(text);
              return; // Open only one
          }
      }
  }

  void _openAddRecipeDialog(String url) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AddRecipeDialog(initialUrl: url),
      );
  }

  @override
  void dispose() {
    _intentSub?.cancel();
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

  Future<void> _launchApkDownload() async {
    final Uri url = Uri.parse('${AppConfig.apiBaseUrl}/app-release.apk');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de descarga')),
      );
    }
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
        actions: [
          if (kIsWeb)
            IconButton(
              tooltip: "Descargar App Android",
              icon: const Icon(Icons.android, color: Colors.green),
              onPressed: _launchApkDownload,
            ),
        ],
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile List View (re-using RecipeCard but in list format)
                  // Using GridView with crossAxisCount 1 to keep similar structure or ListView
                  // Let's stick to GridView responsive logic entirely or ListView with fixed height
                  return ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        height: 320, // Fixed height for card in list
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: RecipeCard(recipe: recipes[index]),
                        ),
                      );
                    },
                  );
                } else {
                  // Tablet/Desktop Grid View
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      childAspectRatio: 0.8, // Adjust based on card content
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(recipe: recipes[index]);
                    },
                  );
                }
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
