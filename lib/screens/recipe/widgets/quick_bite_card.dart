import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../utils/app_colors.dart';
import '../../recipe/recipe_detail_screen.dart';

class QuickBiteCard extends StatelessWidget {
  final Recipe recipe;

  const QuickBiteCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Imagen Cuadrada tipo "Bite"
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: recipe.imageUrl != null
                  ? Image.network(
                      recipe.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(width: 80, height: 80, color: Colors.grey[200]),
            ),
            const SizedBox(width: 15),
            
            // Información de la Receta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Mostramos conteo de ingredientes y tiempo
                    "${recipe.ingredients.length} ingredients • ${recipe.cookingTime}",
                    style: const TextStyle(color: Color(0xFF61896F), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tags de salud (puedes dinamizar esto luego)
                  Row(
                    children: [
                      _buildTag("KETO"),
                      const SizedBox(width: 8),
                      _buildTag("HIGH PROTEIN"),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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