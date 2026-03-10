import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../services/admin_service.dart';
import '../../controllers/pantry_controller.dart';
import '../../controllers/shopping_list_controller.dart';
import '../../models/recipe_model.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
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
                  icon: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.orange,
                  ),
                  onPressed: _showReportDialog,
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

      // Botón EMPEZAR A COCINAR fijo
      bottomSheet: Container(
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
          onPressed: _startCooking,
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
