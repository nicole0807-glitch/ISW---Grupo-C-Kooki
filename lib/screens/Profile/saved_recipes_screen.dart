import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kooki/controllers/favorites_controller.dart';
import 'package:kooki/services/recipe_service.dart';
import 'package:kooki/models/recipe_model.dart';
import 'package:kooki/models/user_recipe_model.dart';
import 'package:kooki/screens/recipe/widgets/recipe_card.dart';

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

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
              future: Future.wait([
                RecipeService().fetchRecipes(),
                RecipeService().fetchCommunityRecipes(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error al cargar las recetas",
                      style: TextStyle(color: Colors.red.shade400),
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
                          childAspectRatio:
                              0.65, // Ajustar según el ratio del RecipeCard
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: savedRecipes.length,
                    itemBuilder: (context, index) {
                      // El RecipeCard ya tiene un margen derecho y bottom por defecto
                      // Podemos envolverlo en MediaQuery o FractionallySizedBox si fuera necesario
                      // pero el GridView forza el tamaño del hijo.
                      // Quitamos el margin derecho del card pasándole un flag si es necesario,
                      // o usamos un wrapper. El card original tiene margin a la derecha fijo,
                      // para el grid lo compensamos.
                      return Transform.translate(
                        offset: const Offset(
                          10,
                          0,
                        ), // Ajuste por el margen derecho del card original
                        child: RecipeCard(recipe: savedRecipes[index]),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
