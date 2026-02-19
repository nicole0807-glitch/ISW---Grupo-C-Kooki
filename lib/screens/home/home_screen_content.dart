import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';
import '../../utils/app_colors.dart';
import '../admin/admin_dashboard_screen.dart';
import '../recipe/validation_queue_screen.dart';
import '../recipe/widgets/quick_bite_card.dart';
import '../recipe/widgets/recipe_card.dart';

enum HomeRecipeFilter { all, topRated, quickBites, favorites }

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final RecipeService _recipeService = RecipeService();
  late final Future<List<Recipe>> _recipesFuture;

  String _query = '';
  HomeRecipeFilter _selectedFilter = HomeRecipeFilter.all;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _recipeService.fetchRecipes();
  }

  List<Recipe> _applyFilters(List<Recipe> recipes, FavoritesController favorites) {
    return recipes.where((recipe) {
      final queryMatch =
          _query.isEmpty ||
          recipe.title.toLowerCase().contains(_query) ||
          recipe.ingredients.any((i) => i.name.toLowerCase().contains(_query));

      if (!queryMatch) {
        return false;
      }

      switch (_selectedFilter) {
        case HomeRecipeFilter.all:
          return true;
        case HomeRecipeFilter.topRated:
          return recipe.rating >= 4.5;
        case HomeRecipeFilter.quickBites:
          return recipe.tagIds.contains(22);
        case HomeRecipeFilter.favorites:
          return favorites.isFavorite(recipe.id);
      }
    }).toList();
  }

  Widget _filterChip(String label, HomeRecipeFilter filter) {
    final selected = _selectedFilter == filter;

    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.nutveSelectionGreen.withOpacity(0.25),
      checkmarkColor: AppColors.nutveDarkGreen,
      onSelected: (_) => setState(() => _selectedFilter = filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final favorites = context.watch<FavoritesController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.nutveDarkGreen,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Desbloquea tu \nPotencial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.nutveDarkGreen,
                  ),
                  onPressed: () {},
                  child: const Text('MEJORAR PLAN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (homeController.isNutricionista) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ValidationQueueScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check),
                label: const Text('COLA DE VALIDACION'),
              ),
            ),
            const SizedBox(height: 15),
          ],
          if (homeController.isAdmin) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2521),
                  foregroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.dashboard),
                label: const Text('ADMIN DASHBOARD'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar receta...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('Todas', HomeRecipeFilter.all),
              _filterChip('Top Rated', HomeRecipeFilter.topRated),
              _filterChip('Quick Bites', HomeRecipeFilter.quickBites),
              _filterChip('Favoritas', HomeRecipeFilter.favorites),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Recipe>>(
            future: _recipesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.nutveDarkGreen),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar recetas: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No se encontraron recetas.'));
              }

              final filteredRecipes = _applyFilters(snapshot.data!, favorites);

              if (filteredRecipes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Sin resultados para tu busqueda.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                );
              }

              final quickBitesRecipes =
                  filteredRecipes.where((r) => r.tagIds.contains(22)).take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recetas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) => RecipeCard(recipe: filteredRecipes[index]),
                    ),
                  ),
                  if (quickBitesRecipes.isNotEmpty) ...[
                    const SizedBox(height: 35),
                    const Text(
                      'Snacks Rapidos y Saludables',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: quickBitesRecipes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 15),
                      itemBuilder: (context, index) => QuickBiteCard(recipe: quickBitesRecipes[index]),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
