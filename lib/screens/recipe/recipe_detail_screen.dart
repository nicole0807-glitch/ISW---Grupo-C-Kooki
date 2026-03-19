import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../controllers/shopping_controller.dart';
import '../../models/recipe_model.dart';
import '../../controllers/cooking_controller.dart';
import '../../models/cooking_models.dart';
import '../../services/admin_service.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final CookingController _cookingController = Get.find<CookingController>();
  final supabase = Supabase.instance.client;
  int _selectedTabIndex = 0;

  void _shareRecipe() {
    final recipeTitle = widget.recipe.title;
    Share.share(
      'Mira esta receta en Kooki: $recipeTitle',
      subject: 'Receta: $recipeTitle',
    );
  }

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

  void _showReportDialog() {
    final reasonController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Reportar Receta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonController,
                    enabled: !isSending,
                    decoration: const InputDecoration(
                      hintText: 'Describe el motivo del reporte...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (reasonController.text.isNotEmpty) {
                            setDialogState(() => isSending = true);
                            try {
                              await AdminService()
                                  .reportRecipe(
                                    recipeId: widget.recipe.id.toString(),
                                    isCommunity: false,
                                    reason: reasonController.text,
                                  )
                                  .timeout(const Duration(seconds: 10));

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Reporte enviado correctamente',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                setDialogState(() => isSending = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enviar Reporte'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onStartCooking() async {
    final result = await _cookingController.validateInventory(widget.recipe.id);
    if (!mounted) return;

    if (result == null) return;

    if (result.canCook) {
      final success = await _cookingController.startCooking(widget.recipe.id);
      if (success && mounted) {
        // Mode Cook
      }
    } else {
      _showMissingIngredientsSheet(result.missing);
    }
  }

  void _showMissingIngredientsSheet(List<MissingIngredient> missing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Estado de selección: todos seleccionados por defecto
    final selected = List<bool>.filled(missing.length, true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final selectedItems = <MissingIngredient>[];
          for (int i = 0; i < missing.length; i++) {
            if (selected[i]) selectedItems.add(missing[i]);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Icono de advertencia
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  "Faltan Ingredientes",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.nutveDarkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtítulo con contador
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "${selectedItems.length} de ${missing.length} seleccionados",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Lista de ingredientes faltantes
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: missing.length,
                    itemBuilder: (context, index) {
                      final item = missing[index];
                      final isSelected = selected[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isSelected
                                    ? AppColors.nutveSelectionGreen.withOpacity(
                                        0.12,
                                      )
                                    : Colors.white.withOpacity(0.05))
                              : (isSelected
                                    ? AppColors.nutveSelectionGreen.withOpacity(
                                        0.08,
                                      )
                                    : Colors.grey.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? (isSelected
                                      ? AppColors.nutveSelectionGreen
                                            .withOpacity(0.3)
                                      : Colors.white10)
                                : (isSelected
                                      ? AppColors.nutveSelectionGreen
                                            .withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.15)),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Ícono de carrito
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: isSelected
                                  ? AppColors.nutveSelectionGreen
                                  : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400]),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            // Nombre y cantidad
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Faltan: ${item.missingQuantity} ${item.unit}",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.redAccent[100]
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Checkbox
                            Checkbox(
                              value: isSelected,
                              activeColor: AppColors.nutveSelectionGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setSheetState(() {
                                  selected[index] = val ?? false;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Botones de acción
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "CANCELAR",
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart, size: 20),
                          label: const Text(
                            "A LA LISTA",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.nutveSelectionGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: selectedItems.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final success = await _cookingController
                                      .addToShoppingList(selectedItems);
                                  if (!mounted) return;
                                  if (success) {
                                    // Refrescar carrito si está registrado
                                    try {
                                      Get.find<ShoppingController>()
                                          .loadCartItems();
                                    } catch (_) {}
                                    _showSuccessOverlay();
                                  }
                                },
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
    );
  }

  /// Overlay central de confirmación con auto-dismiss a 3 segundos.
  void _showSuccessOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (ctx) {
        // Auto-dismiss tras 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.nutveSelectionGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.kitchen,
                      size: 48,
                      color: AppColors.nutveSelectionGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "¡Ingredientes agregados!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.nutveDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Puedes gestionarlos en tu Carrito dentro de la sección Despensa.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Future<void> _startCooking() async {
    final pantryController = Get.find<PantryController>();
    final shoppingController = Get.put(ShoppingListController());

    List<Map<String, dynamic>> missingIngredients = [];
    List<Map<String, dynamic>> matchedIngredients = [];

    // Simple matching algorithm
    for (var recipeIng in widget.recipe.ingredients) {
      double requiredAmount = recipeIng.amount;

      final recipeNameLower = recipeIng.name.toLowerCase();
      // Find matching item in pantry
      final pantryIndex = pantryController.allIngredients.indexWhere(
        (pi) =>
            pi.displayName.toLowerCase().contains(recipeNameLower) ||
            recipeNameLower.contains(pi.displayName.toLowerCase()),
      );

      if (pantryIndex != -1) {
        final pantryIng = pantryController.allIngredients[pantryIndex];
        if (pantryIng.quantity >= requiredAmount) {
          // Has enough
          matchedIngredients.add({
            'pantryIng': pantryIng,
            'amountToDeduct': requiredAmount,
          });
        } else {
          // Not enough quantity
          missingIngredients.add({
            'name': recipeIng.name,
            'amount': requiredAmount - pantryIng.quantity,
            'unit': recipeIng.unit,
          });
        }
      } else {
        // Completely missing
        missingIngredients.add({
          'name': recipeIng.name,
          'amount': requiredAmount,
          'unit': recipeIng.unit,
        });
      }
    }

    if (missingIngredients.isNotEmpty) {
      // Show dialog to add to cart
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ingredientes Faltantes'),
            content: Text(
              'No tienes suficientes ingredientes en tu despensa para cocinar esta receta. Te faltan ${missingIngredients.length} ingredientes.\n\n¿Deseas añadirlos a tu lista de la compra?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                ),
                onPressed: () {
                  shoppingController.addMissingIngredients(missingIngredients);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Añadir al Carrito',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Show confirmation to deduct
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('¡Empezar a Cocinar!'),
            content: const Text(
              'Tienes todos los ingredientes listos. ¿Deseas empezar a cocinar y descontar los ingredientes usados de tu despensa?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Cocinar',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        for (var match in matchedIngredients) {
          try {
            final pantryIng = match['pantryIng'];
            final toDeduct = match['amountToDeduct'];
            pantryIng.quantity = pantryIng.quantity - toDeduct;
            await pantryController.updateIngredient(pantryIng);
          } catch (e) {
            print('Error deducting intedient: $e');
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡A cocinar! Ingredientes descontados de tu despensa.',
              ),
              backgroundColor: AppColors.nutveSelectionGreen,
            ),
          );
        }
      }
    }
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
                  onPressed: _shareRecipe,
                ),
              ),
              const SizedBox(width: 15),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.recipe.imageUrl != null &&
                      widget.recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        alignment: Alignment.center,
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        child: Icon(
                          Icons.image_outlined,
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                          size: 60,
                        ),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                        size: 60,
                      ),
                    ),
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
                  // Título siempre visible
                  Text(
                    widget.recipe.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Perfil del Autor siempre visible (pero sin botón de seguir para invitados)
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
                    trailing: AuthController().hasSession()
                        ? TextButton(
                            onPressed: () {},
                            child: const Text(
                              "SEGUIR",
                              style: TextStyle(
                                color: AppColors.nutveSelectionGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const Divider(),

                  if (!AuthController().hasSession())
                    _buildGuestLockedContent(isDark),
                  if (AuthController().hasSession()) ...[
                    // Rating solo para logueados
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('recipe_ratings')
                          .stream(primaryKey: ['id'])
                          .eq(
                            'recipe_id',
                            widget.recipe.id!,
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
                                ratings.reduce((a, b) => a + b) /
                                ratings.length;
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
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

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
                    _buildTabBar(isDark),

                    // Contenido condicional según pestaña seleccionada
                    const SizedBox(height: 20),
                    if (_selectedTabIndex == 0) ...[
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
                    ],
                    if (_selectedTabIndex == 1) ...[
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
                    ],
                    if (_selectedTabIndex == 2) _buildNutritionContent(isDark),

                    const SizedBox(
                      height: 100,
                    ), // Espacio para el botón flotante
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Botón EMPEZAR A COCINAR fijo (Solo si hay sesión)
      bottomSheet: !AuthController().hasSession()
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              color: isDark
                  ? const Color(0xFF1A1A1A).withOpacity(0.95)
                  : Colors.white.withOpacity(0.9),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _onStartCooking,
                child: const Text(
                  "¡EMPEZAR A COCINAR!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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

  Widget _buildGuestLockedContent(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 60,
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              const Text(
                'Contenido Protegido',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Inicia sesión para ver la receta completa, ingredientes, pasos y valor nutricional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.nutveSelectionGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  "INICIAR SESIÓN",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
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

  Widget _buildTabBar(bool isDark) {
    final tabs = ["Ingredientes", "Instrucciones", "Nutrición"];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppColors.nutveSelectionGreen
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.nutveSelectionGreen
                        : (isDark ? Colors.grey[500] : Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNutritionContent(bool isDark) {
    final nutrition = widget.recipe.nutrition;

    if (nutrition.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.no_food_outlined,
                size: 48,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                "Información nutricional no disponible",
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mapa de íconos para claves comunes de nutrición
    final iconMap = <String, IconData>{
      'calories': Icons.local_fire_department_outlined,
      'calorias': Icons.local_fire_department_outlined,
      'protein': Icons.fitness_center,
      'proteina': Icons.fitness_center,
      'proteinas': Icons.fitness_center,
      'carbs': Icons.grain,
      'carbohidratos': Icons.grain,
      'fat': Icons.opacity,
      'grasa': Icons.opacity,
      'grasas': Icons.opacity,
      'fiber': Icons.eco_outlined,
      'fibra': Icons.eco_outlined,
      'sodium': Icons.water_drop_outlined,
      'sodio': Icons.water_drop_outlined,
      'sugar': Icons.cake_outlined,
      'azucar': Icons.cake_outlined,
      'azúcar': Icons.cake_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Información Nutricional",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...nutrition.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;
          final icon = iconMap[key.toLowerCase()] ?? Icons.info_outline;
          final label = key[0].toUpperCase() + key.substring(1);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.nutveSelectionGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : AppColors.nutveSelectionGreen.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.nutveSelectionGreen, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  "$value",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white70 : AppColors.nutveDarkGreen,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
