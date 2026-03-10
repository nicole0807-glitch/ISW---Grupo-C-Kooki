import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/ingredient.dart';
import '../../../controllers/pantry_controller.dart';
import '../add_ingredient_screen.dart';

class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;

  const IngredientCard({super.key, required this.ingredient});

  Color _getStatusColor() {
    if (ingredient.isExpired) return const Color(0xFFF44336);
    if (ingredient.expiresSoon) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  String _getStatusText() {
    if (ingredient.isExpired) return 'Caducado';
    if (ingredient.expiresSoon) {
      final days = ingredient.daysUntilExpiration ?? 0;
      return 'Caduca en $days días';
    }
    return ingredient.status ?? 'Fresco';
  }

  void _showOptionsMenu(BuildContext context) {
    final controller = Get.find<PantryController>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => AddIngredientScreen(ingredient: ingredient));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PantryController controller) {
    // DEBUG: Ver todos los datos del ingrediente
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 DEBUG - Datos del ingrediente:');
    print('   pantryId: ${ingredient.pantryId}');
    print('   id (getter): ${ingredient.id}');
    print('   ingredientMasterId: ${ingredient.ingredientMasterId}');
    print('   name: ${ingredient.name}');
    print('   userId: ${ingredient.userId}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Intentar obtener el ID: primero pantryId, luego id, luego ingredientMasterId
    final deleteId =
        ingredient.pantryId?.toString() ??
        ingredient.id ??
        ingredient.ingredientMasterId.toString();

    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Ingrediente'),
        content: Text(
          '¿Estás seguro de que quieres eliminar ${ingredient.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Cerrar confirmación

              // Mostrar loading
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                ),
                barrierDismissible: false,
              );

              try {
                print('🔄 Llamando a deleteIngredient con: $deleteId');
                await controller.deleteIngredient(deleteId);

                // Cerrar loading
                Get.back();

                // Mostrar mensaje de éxito
                Get.snackbar(
                  'Éxito',
                  'Ingrediente eliminado correctamente',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF4CAF50),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(10),
                  borderRadius: 8,
                );
              } catch (e) {
                print('❌ Exception en delete: $e');

                // Cerrar loading
                Get.back();

                // Mostrar error
                Get.snackbar(
                  'Error',
                  'No se pudo eliminar: ${e.toString()}',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ingredient.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ingredient.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              : const Icon(Icons.fastfood, color: Colors.grey, size: 30),
        ),
        title: Text(
          ingredient.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${ingredient.displayQuantity} - ${ingredient.category}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _showOptionsMenu(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text(
            'Editar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
