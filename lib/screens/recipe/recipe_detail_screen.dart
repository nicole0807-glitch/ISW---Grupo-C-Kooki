import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../models/recipe_model.dart';
import '../../controllers/cooking_controller.dart';
import '../../models/cooking_models.dart';
import '../../shared/widgets/nutve_navigation_hint.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final CookingController _cookingController = Get.find<CookingController>();
  final supabase = Supabase.instance.client;

  Future<void> _rateRecipe(double ratingValue) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debes iniciar sesión para calificar'),
            ),
          );
        }
        return;
      }

      await supabase.from('recipe_ratings').upsert({
        'recipe_id': widget.recipe.id,
        'user_id': user.id,
        'rating': ratingValue,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu calificación!'),
            backgroundColor: AppColors.nutveSelectionGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la calificación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRatingDialog() {
    double currentRating = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Califica esta receta',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Qué te pareció la receta?'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            currentRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nutveSelectionGreen,
                  ),
                  onPressed: currentRating > 0
                      ? () {
                          Navigator.pop(context);
                          _rateRecipe(currentRating);
                        }
                      : null,
                  child: const Text(
                    'Calificar',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                                Icons.shopping_cart,
                                color: Colors.black,
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
                                NutveNavigationHint.show(context);
                              }
                            },
                      child: _cookingController.isAddingToCart.value
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Agregar al carrito",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.shopping_cart,
                                  color: Colors.black,
                                  size: 22,
                                ),
                              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: isFavorite ? Colors.redAccent : Colors.black54,
                  ),
                  onPressed: () {
                    favorites.toggleFavorite(widget.recipe.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? "Ya no te gusta esta receta"
                              : "¡Te gusta esta receta!",
                        ),
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Botón GUARDAR (Bookmark)
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite
                        ? AppColors.nutveSelectionGreen
                        : Colors.black54,
                  ),
                  onPressed: () {
                    favorites.toggleFavorite(widget.recipe.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? "Receta eliminada de guardados"
                              : "Receta guardada en tu perfil",
                        ),
                        duration: const Duration(milliseconds: 1500),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
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
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Rating
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('recipe_ratings')
                        .stream(primaryKey: ['id'])
                        .eq(
                          'recipe_id',
                          widget.recipe.id,
                        ), // recipe_id para recetas profesionales
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint(
                          'Error en stream de ratings: ${snapshot.error}',
                        );
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        );
                      }

                      double displayRating = 0.0;
                      if (snapshot.hasData) {
                        final ratingsData = snapshot.data!;
                        if (ratingsData.isNotEmpty) {
                          final ratings = ratingsData
                              .map((r) => (r['rating'] as num).toDouble())
                              .toList();
                          displayRating =
                              ratings.reduce((a, b) => a + b) / ratings.length;
                        }
                      }

                      return GestureDetector(
                        onTap: _showRatingDialog,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              displayRating == 0.0
                                  ? "Sin calificar (Toca para votar)"
                                  : "${displayRating.toStringAsFixed(1)} Promedio (Toca para votar)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.recipe.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1B4332),
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
                      "Dra. Sarah Jenkins",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "Nutricionista Principal • Receta Premium",
                    ),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "SEGUIR",
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
                        "Duración",
                        widget.recipe.cookingTime ?? "25 min",
                      ),
                      _buildStat(Icons.payments, "Costo", "Bajo"),
                      _buildStat(
                        Icons.fitness_center,
                        "Dificultad",
                        widget.recipe.difficulty ?? "Fácil",
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
                        Tab(text: "Ingredientes"),
                        Tab(text: "Instrucciones"),
                        Tab(text: "Nutrición"),
                      ],
                    ),
                  ),

                  // Lista de Ingredientes
                  const SizedBox(height: 20),
                  Text(
                    "Ingredientes para 2 porciones",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...widget.recipe.ingredients.map(
                    (ing) => _buildIngredientItem(ing),
                  ),

                  // Pasos (Instructions)
                  const SizedBox(height: 40),
                  Text(
                    "Paso a Paso",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
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
        color: isDark
            ? const Color(0xFF1A1A1A).withOpacity(0.95)
            : Colors.white.withOpacity(0.9),
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
                    "¡EMPEZAR A COCINAR!",
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: isDark ? Colors.grey.shade400 : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
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
