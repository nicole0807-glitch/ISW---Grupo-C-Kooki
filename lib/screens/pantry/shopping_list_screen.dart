import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/ingredient_selector.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShoppingListController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Lista de la Compra",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark
            ? const Color(0xFF1A2A1D)
            : AppColors.nutveDarkGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Borrar completados',
            onPressed: () {
              controller.clearChecked();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  "Tu lista está vacía",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Los ingredientes que te falten para cocinar\naparecerán aquí.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.items.length,
          itemBuilder: (context, index) {
            final item = controller.items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E20) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: item.isChecked
                      ? AppColors.nutveSelectionGreen.withOpacity(0.5)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Checkbox(
                  value: item.isChecked,
                  activeColor: AppColors.nutveSelectionGreen,
                  checkColor: Colors.black,
                  onChanged: (val) {
                    controller.toggleItem(item.id);
                  },
                ),
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: item.isChecked
                        ? Colors.grey
                        : (isDark ? Colors.white : Colors.black87),
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  "${item.amount} ${item.unit}".trim(),
                  style: TextStyle(
                    color: item.isChecked
                        ? Colors.grey
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () {
                    controller.removeItem(item.id);
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.nutveSelectionGreen,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          _showAddItemDialog(context, controller);
        },
      ),
    );
  }

  void _showAddItemDialog(
    BuildContext context,
    ShoppingListController controller,
  ) {
    String name = "";
    double amount = 1.0;
    String unit = "";

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text("Añadir Ingrediente"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IngredientSelector(
                isDark: isDark,
                onSelected: (val) => name = val.name,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(labelText: "Cantidad"),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (val) {
                        amount = double.tryParse(val) ?? 1.0;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      decoration: const InputDecoration(labelText: "Unidad"),
                      onChanged: (val) => unit = val,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
              ),
              onPressed: () {
                if (name.isNotEmpty) {
                  controller.addItem(name, amount, unit);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Añadir",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}
