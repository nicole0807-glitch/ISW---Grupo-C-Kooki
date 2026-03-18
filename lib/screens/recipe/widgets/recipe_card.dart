import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../utils/app_colors.dart';
import '../../recipe/recipe_detail_screen.dart';
import '../../recipe/user_recipe_detail_screen.dart';
import '../../../models/user_recipe_model.dart';
import '../../../controllers/auth_controller.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Lógica dinámica: solo mostramos el label si la calificación es >= 4.5
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.isFavorite(recipe.id);
    final bool isTopRated = recipe.rating >= 4.5;

    return InkWell(
      onTap: () {
        final isCommunityRecipe = int.tryParse(recipe.id.toString()) == null;
        if (isCommunityRecipe) {
          // Si es de comunidad, navegamos al detalle de usuario
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRecipeDetailScreen(
                recipe: UserRecipe(
                  id: recipe.id.toString(),
                  userId: '', // No lo tenemos aquí pero el detalle lo manejará
                  userName: 'Cargando...',
                  title: recipe.title,
                  imageUrl: recipe.imageUrl ?? '',
                  duration: recipe.cookingTime ?? '',
                  cost: recipe.cost ?? '',
                  difficulty: recipe.difficulty ?? '',
                  ingredients: recipe.ingredients.map((i) => i.name).toList(),
                  steps: recipe.steps,
                  nutrition: recipe.nutrition,
                ),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        }
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(
          right: 20,
          bottom: 15,
          top: 5,
        ), // Un poco más de margen
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
              ),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- PARTE SUPERIOR (IMAGEN + OVERLAYS) ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                width: double.infinity,
                                alignment: Alignment.center,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey.shade100,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white24
                                      : Colors.grey.shade400,
                                  size: 40,
                                ),
                              ),
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.grey.shade100,
                          child: Icon(
                            Icons.image_outlined,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white24
                                : Colors.grey.shade400,
                            size: 40,
                          ),
                        ),
                ),

                // BOTÓN DE CORAZÓN (Favoritos)
                if (AuthController().hasSession())
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => favorites.toggleFavorite(recipe.id),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color:
                                  isFavorite ? Colors.redAccent : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // LABEL "TOP RATED"
                if (isTopRated)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.nutveDarkGreen.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "TOP RATED",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // --- INFO DE LA RECETA ---
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF1B4332),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.description ??
                        "Explora esta deliciosa receta saludable.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        recipe.cookingTime ?? "-- min",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF52B788,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty ?? "Media",
                          style: const TextStyle(
                            color: Color(0xFF52B788),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
