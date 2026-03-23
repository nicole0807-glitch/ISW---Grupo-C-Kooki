import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import 'package:intl/intl.dart';
import '../../recipe/review_recipe_screen.dart';
import '../../../widgets/kooki_remote_image.dart';

class HistoryRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const HistoryRecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApproved =
        recipe.status.toLowerCase() == 'aprobado' ||
        recipe.status.toLowerCase() == 'approved';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: KookiRemoteImage(
                imageUrl: recipe.imageUrl,
                bucketHint: 'recipe_images',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: 100,
                  height: 100,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
                color: isApproved ? null : Colors.grey,
                colorBlendMode: isApproved ? null : BlendMode.saturation,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(isApproved),
                      Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Autor: ${recipe.reviewerName ?? "Kooki Chef"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isApproved)
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.cookingTime ?? "15"}m de prep.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewRecipeScreen(
                                recipe: recipe,
                                viewOnly: true,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isApproved ? 'Ver Detalle' : 'Detalles',
                              style: const TextStyle(
                                color: Color(0xFF13EC5B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF13EC5B),
                              size: 16,
                            ),
                          ],
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

  Widget _buildStatusBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? const Color(0xFFD1FAE5) // Emerald-100
            : const Color(0xFFFFE4E6), // Rose-100
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isApproved ? 'APROBADA' : 'RECHAZADA',
        style: TextStyle(
          color: isApproved
              ? const Color(0xFF047857) // Emerald-700
              : const Color(0xFFBE123C), // Rose-700
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
