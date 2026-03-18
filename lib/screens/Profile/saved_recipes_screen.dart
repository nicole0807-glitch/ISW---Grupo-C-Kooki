import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kooki/controllers/favorites_controller.dart';
import 'package:kooki/services/recipe_service.dart';
import 'package:kooki/models/recipe_model.dart';
import 'package:kooki/models/user_recipe_model.dart';
import 'package:kooki/screens/recipe/widgets/recipe_card.dart';

import 'package:kooki/utils/app_colors.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = Future.wait([
        RecipeService().fetchRecipes(),
        RecipeService().fetchCommunityRecipes(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recetas Guardadas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: favorites.favoriteIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aún no tienes recetas guardadas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Explora y guarda tus recetas favoritas\npara verlas aquí.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : FutureBuilder<List<dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: _buildErrorState(
                      "No pudimos cargar tus recetas guardadas.",
                      _loadData,
                    ),
                  );
                }

                if (!snapshot.hasData) return const SizedBox();

                final allRecipes = snapshot.data![0] as List<Recipe>;
                final communityRecipes = snapshot.data![1] as List<UserRecipe>;

                final List<Recipe> savedRecipes = [];

                // Agregar recetas oficiales
                for (var r in allRecipes) {
                  if (favorites.isFavorite(r.id)) {
                    savedRecipes.add(r);
                  }
                }

                // Agregar recetas de la comunidad
                for (var ur in communityRecipes) {
                  if (favorites.isFavorite(ur.id)) {
                    savedRecipes.add(
                      Recipe(
                        id: ur.id,
                        title: ur.title,
                        imageUrl: ur.imageUrl,
                        rating: ur.avgRating,
                        cookingTime: ur.duration,
                        difficulty: ur.difficulty,
                        nutrition: ur.nutrition,
                        ingredients: ur.ingredients
                            .map(
                              (i) => RecipeIngredient(
                                name: i.toString(),
                                amount: 0,
                                unit: '',
                              ),
                            )
                            .toList(),
                        steps: ur.steps.map((s) => s.toString()).toList(),
                        tagIds: [],
                      ),
                    );
                  }
                }

                if (savedRecipes.isEmpty) {
                  return const Center(
                    child: Text("No hay recetas guardadas que mostrar"),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 40),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: savedRecipes.length,
                    itemBuilder: (context, index) {
                      return Transform.translate(
                        offset: const Offset(10, 0),
                        child: RecipeCard(recipe: savedRecipes[index]),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nutveSelectionGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              "Intentar de nuevo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
