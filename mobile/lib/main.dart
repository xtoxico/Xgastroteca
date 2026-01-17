import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/recipe_detail_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: id);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Xgastroteca',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)
        )
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
