import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/constants/app_config.dart';
import 'package:mobile/screens/queue_screen.dart';
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
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  StreamSubscription? _intentSub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Sharing Intent likely NOT supported on Web via this plugin.
    if (!kIsWeb) {
      // Listen to media share (for text/url)
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

    // Check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(recipesListProvider(search: _searchQuery).notifier).fetchNextPage();
    }
  }

  Future<void> _checkVersion() async {
    if (kIsWeb) return; 
    
    try {
      final dio = Dio();
      final res = await dio.get('${AppConfig.apiBaseUrl}/api/version');
      final latestVersion = res.data['latest_app_version'];
      final downloadUrl = res.data['download_url'];

      if (latestVersion != AppConfig.appVersion) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("¡Nueva Versión Disponible!"),
            content: Text("Hay una nueva versión ($latestVersion) disponible. Tienes la ${AppConfig.appVersion}."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ignorar")),
              ElevatedButton(
                onPressed: () {
                  launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
                  Navigator.pop(ctx);
                },
                child: const Text("Descargar"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Version check failed: $e");
    }
  }

  void _handleSharedText(String text) {
      if (text.startsWith('http')) {
          _openAddRecipeDialog(text);
      }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
      for (var file in files) {
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

  void _performSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
    });
  }

  Future<void> _launchApkDownload() async {
    final Uri url = Uri.parse('https://xgastroteca.antoniotirado.com/app-release.apk');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace de descarga')),
        );
      }
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
          IconButton(
            tooltip: "Cola de Procesamiento",
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              );
            },
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
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                ),
              ),
              onChanged: _performSearch,
            ),
          ),
        ),
      ),
      body: recipesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
             return const Center(child: Text("No hay recetas que coincidan."));
          }

          final isLoadingMore = recipesAsync.isLoading && !recipesAsync.isRefreshing;

          return RefreshIndicator(
            onRefresh: () async {
               return ref.refresh(recipesListProvider(search: _searchQuery).future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: recipes.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == recipes.length) {
                         return const Padding(
                           padding: EdgeInsets.all(16.0),
                           child: Center(child: CircularProgressIndicator()),
                         );
                      }
                      return SizedBox(
                        height: 320, 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: RecipeCard(recipe: recipes[index]),
                        ),
                      );
                    },
                  );
                } else {
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                               return RecipeCard(recipe: recipes[index]);
                            },
                            childCount: recipes.length,
                          ),
                        ),
                      ),
                      if (isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
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
