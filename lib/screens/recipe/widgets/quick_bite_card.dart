import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../utils/app_colors.dart';
import '../../recipe/recipe_detail_screen.dart';

class QuickBiteCard extends StatelessWidget {
  final Recipe recipe;

  const QuickBiteCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1B4332);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade50,
          ),
        ),
        child: Row(
          children: [
            // Imagen Cuadrada tipo "Bite"
            Hero(
              tag: 'bite_${recipe.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 85,
                        height: 85,
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Información de la Receta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${recipe.ingredients.length} ing. • ${recipe.cookingTime}",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tags de salud
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTag("KETO"),
                        const SizedBox(width: 6),
                        _buildTag("PROTEIN+"),
                        const SizedBox(width: 6),
                        _buildTag("FIT"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade300,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las etiquetas nutricionales
  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.nutveSelectionGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.nutveSelectionGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
