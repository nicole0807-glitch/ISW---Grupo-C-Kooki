import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/pantry_controller.dart'; // Added PantryController import
import '../../controllers/shopping_list_controller.dart'; // Added ShoppingListController import
import '../../models/user_recipe_model.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';

class UserRecipeDetailScreen extends StatefulWidget {
  final UserRecipe recipe;

  const UserRecipeDetailScreen({super.key, required this.recipe});

  @override
  State<UserRecipeDetailScreen> createState() => _UserRecipeDetailScreenState();
}

class _UserRecipeDetailScreenState extends State<UserRecipeDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;
  final Set<dynamic> _autoModeratedIds = <dynamic>{};

  // Algoritmo básico con palabras ofensivas pre-cargadas.
  static const List<String> _offensiveWords = [
    'idiota',
    'estupido',
    'estúpido',
    'imbecil',
    'imbécil',
    'pendejo',
    'mierda',
    'carajo',
    'fuck',
    'shit',
    'bitch',
  ];

  bool _isReportingDialogLoading = false;

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: !_isReportingDialogLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Denunciar Receta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¿Por qué deseas denunciar esta receta? (Lenguaje ofensivo, contenido inapropiado, etc.)',
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe el motivo...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isReportingDialogLoading
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isReportingDialogLoading
                      ? null
                      : () async {
                          if (reasonController.text.isNotEmpty) {
                            setDialogState(
                              () => _isReportingDialogLoading = true,
                            );
                            try {
                              await AdminService()
                                  .reportRecipe(
                                    recipeId: widget.recipe.id!.toString(),
                                    isCommunity: true,
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
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(
                                  () => _isReportingDialogLoading = false,
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isReportingDialogLoading
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

  // --- 3. FUNCIÓN PARA ENVIAR COMENTARIO (EVITA "ANÓNIMO") ---
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final user = supabase.auth.currentUser;
      // Extraemos el nombre real de los metadatos de Auth para evitar el anonimato
      final String realUserName =
          user?.userMetadata?['full_name'] ??
          user?.userMetadata?['display_name'] ??
          'Usuario kooki';

      await supabase.from('recipe_comments').insert({
        'user_recipe_id': widget.recipe.id,
        'user_id': user?.id,
        'user_name': realUserName, // Se guarda el nombre real
        'comment': text,
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _containsOffensiveLanguage(String text) {
    final normalized = text.toLowerCase();
    return _offensiveWords.any((word) => normalized.contains(word));
  }

  Future<void> _deleteComment(dynamic commentId, {bool silent = false}) async {
    try {
      await supabase.from('recipe_comments').delete().eq('id', commentId);
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comentario eliminado.')));
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  Future<void> _confirmAndDeleteComment(dynamic commentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text(
          '¿Confirmas eliminar este comentario de forma definitiva?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteComment(commentId);
    }
  }

  Future<void> _autoModerateComments(
    List<Map<String, dynamic>> comments,
  ) async {
    for (final comment in comments) {
      final commentId = comment['id'];
      final text = (comment['comment'] ?? '').toString();
      if (commentId == null || _autoModeratedIds.contains(commentId)) {
        continue;
      }
      if (_containsOffensiveLanguage(text)) {
        _autoModeratedIds.add(commentId);
        await _deleteComment(commentId, silent: true);
      }
    }
  }

  Future<void> _startCooking() async {
    final pantryController = Get.find<PantryController>();
    final shoppingController = Get.put(ShoppingListController());

    List<Map<String, dynamic>> missingIngredients = [];
    List<Map<String, dynamic>> matchedIngredients = [];

    // Custom parsing for community text ingredients
    for (String rawString in widget.recipe.ingredients) {
      double requiredAmount = 1.0;
      String unit = '';
      String name = rawString.trim();

      // Attempt to extract amount
      final parts = rawString.trim().split(' ');
      if (parts.isNotEmpty) {
        final firstPart = parts[0];
        // Handle basic fractions like 1/2 or simple numbers
        if (firstPart.contains('/')) {
          final frac = firstPart.split('/');
          if (frac.length == 2 &&
              double.tryParse(frac[0]) != null &&
              double.tryParse(frac[1]) != null) {
            requiredAmount = double.parse(frac[0]) / double.parse(frac[1]);
            name = parts.sublist(1).join(' ').trim();
          }
        } else {
          final parsed = double.tryParse(firstPart);
          if (parsed != null) {
            requiredAmount = parsed;
            name = parts.sublist(1).join(' ').trim();
            // Try to extract unit if possible
            if (parts.length > 2) {
              final possibleUnit = parts[1].toLowerCase();
              if ([
                'taza',
                'tazas',
                'cda',
                'cdita',
                'gramos',
                'gr',
                'kg',
                'litro',
                'ml',
                'unidades',
                'pieza',
              ].contains(possibleUnit)) {
                unit = parts[1];
                name = parts.sublist(2).join(' ').trim();
              }
            }
          }
        }
      }

      final recipeNameLower = name.toLowerCase();

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
            'name': name,
            'amount': requiredAmount - pantryIng.quantity,
            'unit': unit,
          });
        }
      } else {
        // Completely missing
        missingIngredients.add({
          'name': name,
          'amount': requiredAmount,
          'unit': unit,
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
              'No tienes suficientes ingredientes en la despensa para esta receta. Te faltan ${missingIngredients.length} ingredientes.\n\n¿Deseas añadirlos al carrito?',
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
                  'Al Carrito',
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
              'Tienes todo listo. ¿Deseas empezar a cocinar y descontar estos ingredientes de tu despensa?',
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
              content: Text('¡A cocinar! Ingredientes descontados.'),
              backgroundColor: AppColors.nutveSelectionGreen,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        floatingActionButton: !AuthController().hasSession()
            ? null
            : FloatingActionButton.extended(
                onPressed: _startCooking,
                backgroundColor: AppColors.nutveSelectionGreen,
                icon: const Icon(Icons.restaurant_rounded, color: Colors.black),
                label: const Text(
                  "¡EMPEZAR A COCINAR!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(context, isDark),
          ],
          body: Column(
            children: [
              _buildRecipeSummary(isDark),
              if (!AuthController().hasSession())
                _buildGuestLockedContent(isDark)
              else ...[
                TabBar(
                  labelColor: isDark
                      ? AppColors.nutveSelectionGreen
                      : AppColors.nutveDarkGreen,
                  unselectedLabelColor: isDark
                      ? Colors.grey.shade600
                      : Colors.grey,
                  indicatorColor: isDark
                      ? AppColors.nutveSelectionGreen
                      : AppColors.nutveDarkGreen,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: "Ingredientes"),
                    Tab(text: "Pasos"),
                    Tab(text: "Opiniones"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildIngredientsList(isDark),
                      _buildStepsList(isDark),
                      _buildCommentsSection(isDark),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestLockedContent(bool isDark) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
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
                'Receta Protegida',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Inicia sesión para ver los ingredientes, pasos y comentarios de la comunidad.',
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
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : AppColors.nutveDarkGreen,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: isDark ? Colors.black54 : Colors.white,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        // Botón ME GUSTA
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.black54 : Colors.white,
            child: Consumer<FavoritesController>(
              builder: (context, favorites, child) {
                final isFav = favorites.isFavorite(widget.recipe.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav
                        ? Colors.redAccent
                        : (isDark ? Colors.white : Colors.black),
                  ),
                  onPressed: () {
                    favorites.toggleFavorite(widget.recipe.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFav
                              ? "Ya no te gusta esta receta"
                              : "¡Te gusta esta receta!",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        // Botón GUARDAR
        if (AuthController().hasSession()) ...[
          // Botón GUARDAR (Bookmark)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white,
              child: Consumer<FavoritesController>(
                builder: (context, favorites, child) {
                  final isFav = favorites.isFavorite(widget.recipe.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.bookmark : Icons.bookmark_border,
                      color: isFav
                          ? AppColors.nutveSelectionGreen
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    onPressed: () {
                      favorites.toggleFavorite(widget.recipe.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? "Receta removida de guardados"
                                : "Receta guardada en tu perfil",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // Botón REPORTAR (Gavel)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.black54 : Colors.white,
              child: IconButton(
                icon: const Icon(
                  Icons.gavel,
                  color: Colors.red,
                ),
                onPressed: () => _showReportDialog(context),
              ),
            ),
          ),
        ],
        // Botón COMPARTIR (Siempre visible)
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? Colors.black54 : Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.share,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: widget.recipe.imageUrl.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.nutveSelectionGreen.withOpacity(0.5),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      alignment: Alignment.center,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.white24 : Colors.grey.shade400,
                        size: 60,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark
                              ? const Color(0xFF121212)
                              : Colors.white.withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildRecipeSummary(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.nutveSelectionGreen,
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                "Subida por ${widget.recipe.userName}",
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (AuthController().hasSession()) ...[
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E20) : Colors.grey[50],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                    Icons.bolt,
                    widget.recipe.difficulty,
                    "Dificultad",
                    isDark,
                  ),
                  _summaryItem(
                    Icons.payments_outlined,
                    widget.recipe.cost,
                    "Costo",
                    isDark,
                  ),
                  _summaryItem(
                    Icons.schedule,
                    widget.recipe.duration,
                    "Tiempo",
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String value,
    String label,
    bool isDark, {
    bool isStar = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isStar
              ? Colors.amber
              : (isDark
                    ? AppColors.nutveSelectionGreen
                    : AppColors.nutveDarkGreen),
          size: 26,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: widget.recipe.ingredients.length,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E20) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.nutveSelectionGreen,
              size: 22,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                widget.recipe.ingredients[index].toString(),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.recipe.steps.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark
                  ? AppColors.nutveSelectionGreen.withOpacity(0.2)
                  : AppColors.nutveSelectionGreen,
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: isDark ? AppColors.nutveSelectionGreen : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                widget.recipe.steps[index].toString(),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    final isAdmin = context.watch<HomeController>().isAdmin;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('recipe_comments')
                .stream(primaryKey: ['id'])
                .eq('user_recipe_id', widget.recipe.id!)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data!;

              // Moderación automática para admins con algoritmo local de palabras ofensivas.
              if (isAdmin) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _autoModerateComments(comments);
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? Colors.white12
                          : AppColors.nutveSelectionGreen.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: isDark
                            ? Colors.white54
                            : AppColors.nutveDarkGreen,
                      ),
                    ),
                    title: Text(
                      c['user_name'] ?? 'Usuario Nutve',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      c['comment'] ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar comentario',
                            onPressed: () => _confirmAndDeleteComment(c['id']),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        _buildCommentInput(isDark),
      ],
    );
  }

  Widget _buildCommentInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: "Escribe tu opinión...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _isSending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.nutveDarkGreen),
                  onPressed: _sendComment,
                ),
        ],
      ),
    );
  }
}
