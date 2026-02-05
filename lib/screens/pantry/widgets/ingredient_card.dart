import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/ingredient.dart';
import '../../../controllers/pantry_controller.dart';
import '../add_ingredient_screen.dart';

class IngredientCard extends StatelessWidget {
  final Ingredient ingredient;

  const IngredientCard({super.key, required this.ingredient});

  Color _getStatusColor() {
    switch (ingredient.status) {
      case 'Fresh':
        return const Color(0xFF4CAF50); // Verde
      case 'Low Stock':
        return const Color(0xFFFF9800); // Naranja
      case 'Expiring Soon':
        return const Color(0xFFF44336); // Rojo
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    if (ingredient.expirationDate != null) {
      final daysLeft = ingredient.expirationDate!.difference(DateTime.now()).inDays;
      if (daysLeft < 0) {
        return 'Expired';
      } else if (daysLeft == 0) {
        return 'Expires today';
      } else if (daysLeft <= 3) {
        return 'Expires in $daysLeft days';
      }
    }
    return ingredient.status;
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
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => AddIngredientScreen(ingredient: ingredient));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PantryController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete ${ingredient.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteIngredient(ingredient.ingredient_id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
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
            color: Colors.grey[200],
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
          ingredient.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${ingredient.quantity}${ingredient.unit} • ${ingredient.category}',
              style: const TextStyle(
                color: Colors.grey,
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
            'Edit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}