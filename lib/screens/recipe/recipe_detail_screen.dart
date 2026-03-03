import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../models/recipe_model.dart';

import 'package:get/get.dart';
import '../../controllers/cooking_controller.dart';
import '../../models/cooking_models.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final CookingController _cookingController = Get.find<CookingController>();

  void _onStartCooking() async {
    // 1. Validar inventario
    final result = await _cookingController.validateInventory(widget.recipe.id);
    if (!mounted) return;

    if (result == null) return;

    if (result.canCook) {
      // 2. Si tiene todo, ejecutar descuento directamente
      final success = await _cookingController.startCooking(widget.recipe.id);
      if (success && mounted) {
        // Podríamos navegar a un modo "Cook Mode" aquí
      }
    } else {
      // 3. Mostrar interfaz de faltantes
      _showMissingIngredientsSheet(result.missing);
    }
  }

  void _showMissingIngredientsSheet(List<MissingIngredient> missing) {
    Set<int> selectedIndices = {
      for (int i = 0; i < missing.length; i++) i,
    }; // Seleccionar todos por defecto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.nutveAlertRed,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Faltan ingredientes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Agrégalos a tu lista de compras para poder cocinar esta receta pronto.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: missing.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = missing[index];
                        final isSelected = selectedIndices.contains(index);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[100]!),
                            borderRadius: BorderRadius.circular(15),
                            color: isSelected
                                ? AppColors.nutveSelectionGreen.withOpacity(
                                    0.05,
                                  )
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.nutveSelectionGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedIndices.add(index);
                                    } else {
                                      selectedIndices.remove(index);
                                    }
                                  });
                                },
                              ),
                              const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "falta ${item.missingQuantity} ${item.unit}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      setModalState(() {
                        if (selectedIndices.length == missing.length) {
                          selectedIndices.clear();
                        } else {
                          selectedIndices = {
                            for (int i = 0; i < missing.length; i++) i,
                          };
                        }
                      });
                    },
                    icon: Icon(
                      selectedIndices.length == missing.length
                          ? Icons.deselect
                          : Icons.select_all,
                      color: AppColors.nutveSelectionGreen,
                      size: 20,
                    ),
                    label: Text(
                      selectedIndices.length == missing.length
                          ? "Deseleccionar todos"
                          : "Seleccionar todos",
                      style: const TextStyle(
                        color: AppColors.nutveSelectionGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nutveSelectionGreen,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _cookingController.isAddingToCart.value
                          ? null
                          : () async {
                              final toAdd = selectedIndices
                                  .map((i) => missing[i])
                                  .toList();
                              final success = await _cookingController
                                  .addToShoppingList(toAdd);
                              if (success && mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: _cookingController.isAddingToCart.value
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              "Agregar al 🛒",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final isFavorite = favorites.isFavorite(widget.recipe.id);
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar con Imagen Hero
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.nutveDarkGreen,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.nutveSelectionGreen,
                  ),
                  onPressed: () => favorites.toggleFavorite(widget.recipe.id),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 15),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.recipe.imageUrl != null
                  ? Image.network(widget.recipe.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[200]),
            ),
          ),

          // 2. Contenido de la Receta
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.nutveSelectionGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "4.9 (1.2k reviews)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.recipe.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  // Perfil del Autor (Mockup según Figma)
                  const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(
                        "https://via.placeholder.com/150",
                      ),
                    ),
                    title: const Text(
                      "Dr. Sarah Jenkins",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Lead Nutritionist • Premium Recipe"),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "FOLLOW",
                        style: TextStyle(
                          color: AppColors.nutveSelectionGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),

                  // Stats (Duración, Costo, Dificultad)
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        Icons.schedule,
                        "Duration",
                        widget.recipe.cookingTime ?? "25 mins",
                      ),
                      _buildStat(Icons.payments, "Cost", "Low"),
                      _buildStat(
                        Icons.fitness_center,
                        "Difficulty",
                        widget.recipe.difficulty ?? "Easy",
                      ),
                    ],
                  ),

                  // Tabs
                  const SizedBox(height: 30),
                  const DefaultTabController(
                    length: 3,
                    child: TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.nutveSelectionGreen,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: "Ingredients"),
                        Tab(text: "Instructions"),
                        Tab(text: "Nutrition"),
                      ],
                    ),
                  ),

                  // Lista de Ingredientes
                  const SizedBox(height: 20),
                  Text(
                    "Ingredients for 2 servings",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  ...widget.recipe.ingredients.map(
                    (ing) => _buildIngredientItem(ing),
                  ),

                  // Pasos (Instructions)
                  const SizedBox(height: 40),
                  const Text(
                    "Step-by-Step",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...widget.recipe.steps.asMap().entries.map(
                    (entry) => _buildStepItem(entry.key + 1, entry.value),
                  ),

                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),

      // Botón START COOKING fijo
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white.withOpacity(0.9),
        child: Obx(
          () => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nutveSelectionGreen,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed:
                _cookingController.isValidating.value ||
                    _cookingController.isCooking.value
                ? null
                : _onStartCooking,
            child:
                _cookingController.isValidating.value ||
                    _cookingController.isCooking.value
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    "START COOKING",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(RecipeIngredient ing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[100]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            "${ing.amount} ${ing.unit}",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.nutveSelectionGreen,
            radius: 15,
            child: Text(
              "$number",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(height: 1.5, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
