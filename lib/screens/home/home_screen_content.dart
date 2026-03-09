import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kooki/screens/recipe/widgets/quick_bite_card.dart';
import 'package:kooki/screens/recipe/widgets/recipe_card.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/recipe_model.dart';
import '../../models/user_recipe_model.dart';
import '../../services/admin_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_colors.dart';
import '../recipe/validation_queue_screen.dart';
import '../recipe/publish_recipe_screen.dart';
import '../recipe/user_recipe_detail_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'main_layout.dart';

enum HomeRecipeFilter { all, topRated, quickBites, favorites, easy, fast }

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final RecipeService _recipeService = RecipeService();

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
          // Quick recipes: cooking time mentions <= 20 minutes
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
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 20),
              // Eliminado el botón duplicado de Cola de Validación
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip(
                      '✨ Todas',
                      HomeRecipeFilter.all,
                      context,
                      icon: null,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '⭐ Top Rated',
                      HomeRecipeFilter.topRated,
                      context,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '🥪 Snacks',
                      HomeRecipeFilter.quickBites,
                      context,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      '❤️ Favoritos',
                      HomeRecipeFilter.favorites,
                      context,
                    ),
                    const SizedBox(width: 8),
                    _filterChip('🟢 Fáciles', HomeRecipeFilter.easy, context),
                    const SizedBox(width: 8),
                    _filterChip('⚡ Rápidas', HomeRecipeFilter.fast, context),
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
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: AppColors.nutveDarkGreen,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar recetas'));
                  }

                  final recipes = snapshot.data ?? [];
                  if (recipes.isEmpty) {
                    return const SizedBox();
                  }

                  final filteredRecipes = _applyFilters(recipes, favorites);

                  if (filteredRecipes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Sin resultados para tu búsqueda.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  final quickBitesFiltered = filteredRecipes
                      .where((r) => r.tagIds.contains(22))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Recetas'),
                      const SizedBox(height: 15),
                      _buildHorizontalList(filteredRecipes),
                      if (quickBitesFiltered.isNotEmpty) ...[
                        const SizedBox(height: 35),
                        _buildSectionHeader('Snacks Rápidos y Saludables'),
                        const SizedBox(height: 10),
                        _buildVerticalList(quickBitesFiltered),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              _buildCommunityHeader(
                context,
                canPublishCommunity: canPublishCommunity,
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<UserRecipe>>(
                future: _recipeService.fetchCommunityRecipes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: CircularProgressIndicator(
                          color: AppColors.nutveSelectionGreen,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyCommunity();
                  }

                  final communityRecipes = snapshot.data!;
                  return SizedBox(
                    height: 320, // Ajustado para evitar recortes de sombra
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.none, // IMPORTANTE
                      padding: const EdgeInsets.only(left: 5, bottom: 20),
                      itemCount: communityRecipes.length,
                      itemBuilder: (context, index) => _buildUserRecipeCard(
                        context,
                        communityRecipes[index],
                        canModerateCommunity,
                      ),
                    ),
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
                      child: Image.network(
                        recipe.imageUrl,
                        height: 150, // Reduced from 180
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (recipe.avgRating >= 4.5)
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
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
                          fontSize: 16, // Reduced from 18
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
                      const SizedBox(height: 12), // Reduced spacing
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
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF52B788).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  recipe.avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFF52B788),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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

  Widget _buildHeroBanner() {
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
            // Background Gradient
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
            // Decorative shapes
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
                  const SizedBox(height: 16),
                  const Text(
                    'Desbloquea tu\nMejor Versión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Planes personalizados y recetas únicas.',
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
                      final mainState = context
                          .findAncestorStateOfType<MainLayoutState>();
                      if (mainState != null) {
                        mainState.navigateToPlan();
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MEJORAR MI PLAN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
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

  // Search bar removed - available in dedicated Search tab

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
      height: 360, // Aumentado para evitar overflows (antes era 310)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // IMPORTANTE para sombras y evitar recortes
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
        Builder(
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
          // Ocupamos el espacio para mantener el alineado si es necesario,
          // o simplemente no mostramos nada.
          const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildSmallTag(
    IconData icon,
    String text, {
    Color color = Colors.grey,
    bool isDark = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
