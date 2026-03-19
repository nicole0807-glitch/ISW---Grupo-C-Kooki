import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/cooking_controller.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../models/recipe_model.dart';
import '../../models/cooking_models.dart';
import 'widgets/rating_bottom_sheet.dart';
import 'widgets/rating_success_dialog.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final CookingController _cookingController = Get.find<CookingController>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Pestaña activa (0=Ingredientes, 1=Instrucciones, 2=Nutrición)
  int _selectedTab = 0;

  // ── Estado reactivo del rating ──────────────────────────────────────────────
  /// Voto que el usuario autenticado ya dio (0 = sin votar).
  int _currentRating = 0;

  /// Promedio visual mostrado en pantalla (se actualiza de forma optimista).
  double _displayAverage = 0.0;

  /// Total de votos conocido (para recalcular el promedio localmente).
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _displayAverage = widget.recipe.rating;
    _loadUserRatingAndAverage();
  }

  /// Carga en paralelo: (a) el voto previo del usuario y (b) el promedio real.
  Future<void> _loadUserRatingAndAverage() async {
    final user = _supabase.auth.currentUser;
    // No cortamos si user == null para al menos cargar el promedio global
    try {
      final allRatings = await _supabase
          .from('recipe_ratings')
          .select('rating, user_id')
          .eq('recipe_id', widget.recipe.id);

      if (!mounted) return;

      final list = List<Map<String, dynamic>>.from(allRatings as List);
      final total = list.length;
      final avg = total > 0
          ? list.map((r) => (r['rating'] as int)).reduce((a, b) => a + b) /
                total
          : 0.0;

      int myRating = 0;
      if (user != null) {
        final myRow = list.firstWhere(
          (r) => r['user_id'] == user.id,
          orElse: () => {},
        );
        myRating = (myRow['rating'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalVotes = total;
          _displayAverage = avg;
          _currentRating = myRating;
        });
      }
    } catch (e) {
      debugPrint('Error cargando ratings: $e');
    }
  }

  // ── Compartir ───────────────────────────────────────────────────────────────
  void _shareRecipe() {
    final title = widget.recipe.title;
    Share.share(
      '¡Mira esta increíble receta de "$title" en Kooki! 🍽️\n'
      'Descarga la app y cocina recetas deliciosas y saludables.',
      subject: 'Receta: $title - Kooki',
    );
  }

  // ── Abrir sheet de calificación con Optimistic UI Update ───────────────────
  Future<void> _openRatingSheet() async {
    final newStars = await RatingBottomSheet.show(
      context,
      recipeId: widget.recipe.id,
      recipeTitle: widget.recipe.title,
      initialRating: _currentRating,
    );

    if (newStars == null || !mounted) return;

    final previousRating = _currentRating;
    final wasAlreadyVoted = previousRating > 0;

    setState(() {
      _currentRating = newStars;
      if (wasAlreadyVoted) {
        final sumWithoutOld = (_displayAverage * _totalVotes) - previousRating;
        _displayAverage = (sumWithoutOld + newStars) / _totalVotes;
      } else {
        final newTotal = _totalVotes + 1;
        _displayAverage =
            ((_displayAverage * _totalVotes) + newStars) / newTotal;
        _totalVotes = newTotal;
      }
    });

    if (mounted) await RatingSuccessDialog.show(context);
    _loadUserRatingAndAverage();
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
        // Navegar a cook mode...
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
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
              // Botón ME GUSTA (Corazón)
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
                  onPressed: _shareRecipe,
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
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.nutveSelectionGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "${_displayAverage.toStringAsFixed(1)} ($_totalVotes ${_totalVotes == 1 ? 'reseña' : 'reseñas'})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openRatingSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _currentRating > 0
                                ? const Color(0xFFFFF8E1)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _currentRating > 0
                                  ? const Color(0xFFFFC107)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentRating > 0
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 16,
                                color: _currentRating > 0
                                    ? const Color(0xFFFFC107)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentRating > 0
                                    ? 'Tu voto: $_currentRating'
                                    : 'Calificar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _currentRating > 0
                                      ? const Color(0xFFFFA000)
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                  // Perfil del Autor
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStat(
                          Icons.schedule,
                          "Duración",
                          widget.recipe.cookingTime ?? "25 min",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStat(Icons.payments, "Costo", "Bajo"),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStat(
                          Icons.fitness_center,
                          "Dificultad",
                          widget.recipe.difficulty ?? "Fácil",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildTabSelector(),
                  const SizedBox(height: 20),
                  _buildTabContent(),
                  const SizedBox(height: 100),
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

  Widget _buildTabSelector() {
    const tabs = ["Ingredientes", "Instrucciones", "Nutrición"];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final isSelected = _selectedTab == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.nutveSelectionGreen
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ingredientes para 2 porciones",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),
            ...widget.recipe.ingredients.map(
              (ing) => _buildIngredientItem(ing),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Paso a Paso",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            ...widget.recipe.steps.asMap().entries.map(
              (entry) => _buildStepItem(entry.key + 1, entry.value),
            ),
          ],
        );
      case 2:
      default:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Próximamente",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "La información nutricional\nestará disponible muy pronto.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStat(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
