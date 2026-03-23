import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'package:kooki/screens/recipe/widgets/quick_bite_card.dart';
import 'package:kooki/screens/recipe/widgets/recipe_card.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/recipe_model.dart';
import '../../models/user_recipe_model.dart';
import '../../services/admin_service.dart';
import '../../services/recipe_service.dart';
import '../../controllers/perfect_match_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/kooki_remote_image.dart';
import '../recipe/validation_queue_screen.dart';
import '../recipe/publish_recipe_screen.dart';
import '../recipe/user_recipe_detail_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';
import 'main_layout.dart';

enum HomeRecipeFilter { all, topRated, quickBites, favorites, easy, fast }

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final RecipeService _recipeService = RecipeService();
  final PerfectMatchController _perfectMatchController = Get.put(
    PerfectMatchController(),
  );

  HomeRecipeFilter _selectedFilter = HomeRecipeFilter.all;

  List<Recipe> _applyFilters(
    List<Recipe> recipes,
    FavoritesController favorites,
  ) {
    return recipes.where((recipe) {
      switch (_selectedFilter) {
        case HomeRecipeFilter.all:
          return true;
        case HomeRecipeFilter.topRated:
          return recipe.rating >= 4.0;
        case HomeRecipeFilter.quickBites:
          return recipe.tagIds.contains(22);
        case HomeRecipeFilter.favorites:
          return favorites.isFavorite(recipe.id);
        case HomeRecipeFilter.easy:
          return (recipe.difficulty?.toLowerCase() ?? '') == 'fácil' ||
              (recipe.difficulty?.toLowerCase() ?? '') == 'facil' ||
              (recipe.difficulty?.toLowerCase() ?? '') == 'easy';
        case HomeRecipeFilter.fast:
          final t = (recipe.cookingTime?.toLowerCase() ?? '');
          final mins = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
          return mins <= 20;
      }
    }).toList();
  }

  Widget _filterChip(
    String label,
    HomeRecipeFilter filter,
    BuildContext context, {
    IconData? icon,
  }) {
    final selected = _selectedFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF52B788)
              : isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF52B788).withOpacity(0.35)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 8 : 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: selected
                ? const Color(0xFF52B788)
                : isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? Colors.white
                    : isDark
                    ? Colors.white70
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : isDark
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final favorites = context.watch<FavoritesController>();
    final canValidate = homeController.hasPermission(
      AppPermission.validateRecipes,
    );
    final canOpenAdmin = homeController.hasPermission(
      AppPermission.openAdminDashboard,
    );
    final canModerateCommunity = homeController.hasPermission(
      AppPermission.moderateCommunityRecipes,
    );
    final canPublishCommunity = homeController.hasPermission(
      AppPermission.publishCommunityRecipe,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColors.nutveDarkGreen,
        onRefresh: () async {
          await _perfectMatchController.findPerfectMatches();
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(AuthController().hasSession()),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip(
                      'Todas',
                      HomeRecipeFilter.all,
                      context,
                      icon: null,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Top Rated',
                      HomeRecipeFilter.topRated,
                      context,
                    ),
                    const SizedBox(width: 8),
                    _filterChip('Snacks', HomeRecipeFilter.quickBites, context),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Favoritos',
                      HomeRecipeFilter.favorites,
                      context,
                    ),
                    const SizedBox(width: 8),
                    _filterChip('Fáciles', HomeRecipeFilter.easy, context),
                    const SizedBox(width: 8),
                    _filterChip('Rápidas', HomeRecipeFilter.fast, context),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (canValidate || canOpenAdmin) ...[
                Row(
                  children: [
                    if (canValidate)
                      Expanded(
                        child: _buildActionButton(
                          'Validar',
                          Icons.fact_check_rounded,
                          Colors.blueAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ValidationQueueScreen(),
                            ),
                          ),
                        ),
                      ),
                    if (canValidate && canOpenAdmin) const SizedBox(width: 12),
                    if (canOpenAdmin)
                      Expanded(
                        child: _buildActionButton(
                          'Admin',
                          Icons.psychology_rounded,
                          Colors.amber,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 25),
              FutureBuilder<List<Recipe>>(
                future: _recipeService.fetchRecipes(),
                builder: (context, proSnapshot) {
                  final recipes = proSnapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (proSnapshot.hasError)
                        _buildErrorState(
                          'No pudimos cargar las recetas. Revisa tu conexión.',
                          () => setState(() {}),
                        )
                      else if (proSnapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: AppColors.nutveDarkGreen,
                            ),
                          ),
                        )
                      else if (recipes.isNotEmpty) ...[
                        _buildSectionHeader('Recetas Profesionales'),
                        const SizedBox(height: 15),
                        _buildHorizontalList(_applyFilters(recipes, favorites)),

                        const SizedBox(height: 40),
                        // Pantry Recommendations (Perfect Match Logic)
                        Builder(
                          builder: (context) {
                            final hasSession = AuthController().hasSession();

                            if (!hasSession) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 35),
                                  _buildSectionHeader('Puedes hacer ahora 🥘'),
                                  _buildGuestSectionPlaceholder(
                                    "Inicia sesión para ver qué puedes cocinar con lo que tienes en casa.",
                                  ),
                                ],
                              );
                            }

                            // Separamos los observables para evitar animaciones
                            // inestables cuando una lista cambia y la otra no.
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 35),
                                _buildSectionHeader('Puedes hacer ahora 🥘'),
                                Obx(() {
                                  final perfectMatches =
                                      _perfectMatchController.perfectMatches;
                                  if (perfectMatches.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 15),
                                      child: Text(
                                        "Suma ingredientes a tu Despensa para encontrar tu Partido Perfecto",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: [
                                      const SizedBox(height: 15),
                                      _buildMixedHorizontalList(perfectMatches),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 35),
                                _buildSectionHeader(
                                  'Por completar (te falta 1 o 2) 🛒',
                                ),
                                Obx(() {
                                  final closeMatches =
                                      _perfectMatchController.closeMatches;
                                  if (closeMatches.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 15),
                                      child: Text(
                                        "Sigue agregando a tu Despensa...",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: [
                                      const SizedBox(height: 15),
                                      _buildMixedHorizontalList(closeMatches),
                                    ],
                                  );
                                }),
                              ],
                            );
                          },
                        ),

                        // Snacks Section
                        Builder(
                          builder: (context) {
                            final quickBites = _applyFilters(
                              recipes,
                              favorites,
                            ).where((r) => r.tagIds.contains(22)).toList();
                            if (quickBites.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 35),
                                  _buildSectionHeader('Snacks Rápidos'),
                                  const SizedBox(height: 10),
                                  _buildVerticalList(quickBites),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                      const SizedBox(height: 40),
                      _buildCommunityHeader(
                        context,
                        canPublishCommunity:
                            canPublishCommunity &&
                            AuthController().hasSession(),
                      ),
                      const SizedBox(height: 15),
                      FutureBuilder<List<UserRecipe>>(
                        future: _recipeService.fetchCommunityRecipes(),
                        builder: (context, comSnapshot) {
                          if (comSnapshot.hasError) {
                            return const SizedBox(); // Silently hide or show minimal error for secondary sections
                          }
                          if (comSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(30.0),
                                child: CircularProgressIndicator(
                                  color: AppColors.nutveSelectionGreen,
                                ),
                              ),
                            );
                          }
                          final communityRecipes = comSnapshot.data ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              if (communityRecipes.isNotEmpty)
                                SizedBox(
                                  height: 295,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    padding: const EdgeInsets.only(
                                      left: 5,
                                      bottom: 20,
                                    ),
                                    itemCount: communityRecipes.length,
                                    itemBuilder: (context, index) =>
                                        _buildUserRecipeCard(
                                          context,
                                          communityRecipes[index],
                                          canModerateCommunity,
                                        ),
                                  ),
                                )
                              else
                                _buildEmptyCommunity(),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Intentar de nuevo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRecipeCard(
    BuildContext context,
    UserRecipe recipe,
    bool isAdmin,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Theme.of(context).cardColor : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRecipeDetailScreen(recipe: recipe),
            ),
          ),
          child: Container(
            width: 250,
            margin: const EdgeInsets.only(right: 15, bottom: 15, top: 5),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: recipe.imageUrl.isNotEmpty
                          ? KookiRemoteImage(
                              imageUrl: recipe.imageUrl,
                              bucketHint: 'recipe_images',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 150,
                              width: double.infinity,
                              alignment: Alignment.center,
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              child: Icon(
                                Icons.image_outlined,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                                size: 40,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.nutveDarkGreen.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "COMUNIDAD",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B4332),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 13,
                            color: isDark
                                ? AppColors.nutveSelectionGreen
                                : AppColors.nutveDarkGreen,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              recipe.userName,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.duration.isNotEmpty
                                ? recipe.duration
                                : "-- min",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 10,
            right: 30,
            child: GestureDetector(
              onTap: () => _confirmRecipeDeletion(context, recipe),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: const Icon(
                  Icons.delete_sweep,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmRecipeDeletion(BuildContext context, UserRecipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Receta'),
        content: Text("¿Deseas eliminar '${recipe.title}' de la comunidad?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService().deleteRecipe(recipe.id, false);
              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Confirmar Borrado'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool hasSession) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.nutveSelectionGreen.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.nutveSelectionGreen,
                      AppColors.nutveDarkGreen.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasSession)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "NUEVO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (hasSession) const SizedBox(height: 16),
                  Text(
                    hasSession
                        ? 'Desbloquea tu\nMejor Versión'
                        : 'Cocina de Forma\nInteligente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasSession
                        ? 'Planes personalizados y recetas únicas.'
                        : 'Organiza tu despensa, ahorra tiempo y descubre cientos de recetas a tu medida.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.nutveDarkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      if (hasSession) {
                        final mainState = context
                            .findAncestorStateOfType<MainLayoutState>();
                        if (mainState != null) {
                          mainState.navigateToPlan();
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasSession ? 'MEJORAR MI PLAN' : 'INICIAR SESIÓN',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Ver todo',
            style: TextStyle(color: AppColors.nutveSelectionGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(List<Recipe> recipes) {
    return SizedBox(
      height: 335,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: recipes.length,
        itemBuilder: (context, index) => RecipeCard(recipe: recipes[index]),
      ),
    );
  }

  Widget _buildVerticalList(List<Recipe> recipes) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recipes.length > 3 ? 3 : recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) => QuickBiteCard(recipe: recipes[index]),
    );
  }

  Widget _buildCommunityHeader(
    BuildContext context, {
    required bool canPublishCommunity,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Builder(
            builder: (ctx) {
              final isDarkCtx = Theme.of(ctx).brightness == Brightness.dark;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comunidad kooki',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkCtx ? Colors.white : null,
                    ),
                  ),
                  Text(
                    'La mejor inspiración para cocinar',
                    style: TextStyle(
                      color: isDarkCtx ? Colors.white54 : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (canPublishCommunity)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublishRecipeScreen()),
            ),
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.nutveDarkGreen,
              size: 30,
            ),
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildGuestSectionPlaceholder(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: Text(
              "Iniciar Sesión",
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixedHorizontalList(List<dynamic> recipes) {
    final canModerate = context.read<HomeController>().hasPermission(
      AppPermission.moderateCommunityRecipes,
    );
    return SizedBox(
      height: 340,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final r = recipes[index];
          if (r is Recipe) {
            return RecipeCard(recipe: r);
          } else {
            return _buildUserRecipeCard(context, r as UserRecipe, canModerate);
          }
        },
      ),
    );
  }

  Widget _buildEmptyCommunity() {
    return const Center(
      child: Text(
        '¡Aún no hay recetas aquí!',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
