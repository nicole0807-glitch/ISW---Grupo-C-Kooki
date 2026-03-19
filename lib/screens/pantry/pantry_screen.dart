import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import 'add_ingredient_screen.dart';
import 'shopping_cart_screen.dart';
import 'widgets/ingredient_card.dart';
import 'widgets/category_chips.dart';
import '../auth/login_screen.dart';
import '../../widgets/guest_view_placeholder.dart';

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
    shoppingController.loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSession = AuthController().hasSession();

    if (!hasSession) {
      return _buildGuestView(isDark);
    }

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Gestión de despensa',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Botón de carrito animado
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
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: TextField(
                onChanged: controller.setSearchQuery,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Buscar ingredientes...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.nutveSelectionGreen,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Category Chips
          const CategoryChips(),

          // Ingredients Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Obx(
                  () => Text(
                    'Mostrando ${controller.filteredIngredients.length} de ${controller.totalItems} ingredientes',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ingredients List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.nutveSelectionGreen),
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
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'No se encontraron ingredientes'
                            : 'Tu despensa está vacía',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'Prueba con otra búsqueda'
                            : 'Agrega tu primer ingrediente',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.grey[400],
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
            }),
          ),
        ],
      ),

      // Floating Action Button - Premium
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddIngredientScreen(),
            ),
          );
        },
        backgroundColor: AppColors.nutveSelectionGreen,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
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
          color: AppColors.nutveSelectionGreen,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
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

  Widget _buildGuestView(bool isDark) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Tu Despensa',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const GuestViewPlaceholder(
        title: "Gestiona tu cocina",
        description:
            "Inicia sesión para llevar el control de tus ingredientes, ver sus fechas de vencimiento y recibir recomendaciones personalizadas.",
        icon: Icons.inventory_2_outlined,
      ),
    );
  }
}
