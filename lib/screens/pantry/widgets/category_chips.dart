import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/pantry_controller.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final chipBg = isDark ? Colors.white.withOpacity(0.07) : Colors.white;
    final controller = Get.find<PantryController>();

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return Obx(() {
              final isSelected = controller.selectedCategory.value == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.setCategory(category);
                  }
                },
                backgroundColor: chipBg,
                selectedColor: const Color(0xFF4CAF50),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : (isDark ? Colors.white24 : Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              );
            });
          },
        ),
      ),
    );
  }
}
