import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_controller.dart';
import 'add_ingredient_screen.dart';
import 'shopping_cart_screen.dart';
import 'widgets/ingredient_card.dart';
import 'widgets/category_chips.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  late PantryController controller;
  late ShoppingController shoppingController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PantryController());
    shoppingController = Get.put(ShoppingController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar ítems del carrito cada vez que la pantalla aparezca
    // para que el badge siempre esté actualizado
    shoppingController.loadCartItems();
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,  // ← Respetar tema
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,  // ← Respetar tema
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Gestión de despensa',
              style: TextStyle(
                color: textColor,  // ← Respetar tema
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Botón de carrito animado (negro con blanco)
            Obx(() => _buildCartButton()),
            const SizedBox(width: 4),
            // Botón de papelera
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Vaciar despensa',
              onPressed: () => controller.clearAll(context),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: controller.setSearchQuery,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Buscar ingredientes...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.7)),
                filled: true,
                fillColor: isDark 
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Category Chips
          const CategoryChips(),

          // Ingredients Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GetBuilder<PantryController>(
              builder: (controller) => Row(
                children: [
                  Text(
                    'Mostrando ${controller.filteredIngredients.length} de ${controller.totalItems} ingredientes',
                    style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ingredients List
          Expanded(
            child: GetBuilder<PantryController>(
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  );
                }

                if (controller.filteredIngredients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                         color: textColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'No se encontraron ingredientes'
                              : 'Tu despensa está vacía',
                          style: TextStyle(
                            fontSize: 18,
                            color: textColor.withOpacity(0.6), 
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.searchQuery.value.isNotEmpty
                              ? 'Prueba con otra búsqueda'
                              : 'Agrega tu primer ingrediente',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadIngredients,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.filteredIngredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = controller.filteredIngredients[index];
                      return IngredientCard(ingredient: ingredient);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Floating Action Button - CAMBIO AQUÍ
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Opción 1: Con GetX
          // Get.to(() => const AddIngredientScreen());

          // Opción 2: Con Navigator (descomenta si GetX no funciona)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddIngredientScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  /// Botón de carrito con badge de cantidad, fondo negro e icono blanco.
  Widget _buildCartButton() {
    final count = shoppingController.cartCount;

    return GestureDetector(
      onTap: () {
        // Recargar ítems antes de abrir el carrito
        shoppingController.loadCartItems();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShoppingCartScreen()),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black,
                size: 20,
              ),
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
