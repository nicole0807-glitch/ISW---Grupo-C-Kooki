import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/recipe_model.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../utils/app_colors.dart';
import '../../recipe/recipe_detail_screen.dart';

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PARTE SUPERIOR (IMAGEN + OVERLAYS) ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          height: 170, // Un poco más alto para mejor proporción
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 170,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                      : Container(
                          height: 170,
                          color: AppColors.nutveDarkGreen.withOpacity(0.1),
                          child: const Icon(
                            Icons.restaurant,
                            color: AppColors.nutveDarkGreen,
                          ),
                        ),
                ),

                // BOTÓN DE CORAZÓN (Favoritos)
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 18,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => favorites.toggleFavorite(recipe.id),
                    ),
                  ),
                ),

                // LABEL "TOP RATED" (Solo si rating >= 4.5)
                if (isTopRated)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.nutveDarkGreen.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.nutveSelectionGreen,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "MÁS VALORADA",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.nutveDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    recipe.description ??
                        "Explora esta deliciosa receta saludable.",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.cookingTime ?? "-- min",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.nutveSelectionGreen.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          recipe.difficulty ?? "Media",
                          style: const TextStyle(
                            color: AppColors.nutveSelectionGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
