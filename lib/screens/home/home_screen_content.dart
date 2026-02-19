import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Widgets y Modelos
import 'package:kooki/screens/recipe/widgets/quick_bite_card.dart';
import 'package:kooki/screens/recipe/widgets/recipe_card.dart';
import '../../utils/app_colors.dart';
import '../../services/recipe_service.dart';
import '../../services/admin_service.dart'; // Importante para la lógica de borrado
import '../../models/recipe_model.dart';
import '../../models/user_recipe_model.dart';

// Controladores y Pantallas
import '../../controllers/home_controller.dart';
import '../admin/admin_control_panel_screen.dart'; // Tu nueva consola maestra
import '../recipe/publish_recipe_screen.dart';
import '../recipe/user_recipe_detail_screen.dart';

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final RecipeService recipeService = RecipeService();
    final homeController = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.nutveDarkGreen,
        onRefresh: () async {
          // Forzar reconstrucción de los FutureBuilder
          (context as Element).markNeedsBuild();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. BANNER HERO ---
              _buildHeroBanner(),
              const SizedBox(height: 20),

              // --- 2. BOTÓN DE PANEL MAESTRO (SOLO ADMIN) ---
              if (homeController.isAdmin) ...[
                _buildAdminPanelButton(context),
                const SizedBox(height: 20),
              ],

              // --- 3. BARRA DE BÚSQUEDA ---
              _buildSearchBar(),
              const SizedBox(height: 25),

              // --- 4. SECCIÓN RECETAS OFICIALES (PRO) ---
              FutureBuilder<List<Recipe>>(
                future: recipeService.fetchRecipes(),
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
                  if (snapshot.hasError)
                    return const Center(child: Text("Error al cargar recetas"));

                  final recipes = snapshot.data ?? [];
                  if (recipes.isEmpty) return const SizedBox();

                  final topRated = recipes
                      .where((r) => r.rating >= 4.5)
                      .toList();
                  final quickBites = recipes
                      .where((r) => r.tagIds.contains(22))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Más Populares"),
                      const SizedBox(height: 15),
                      _buildHorizontalList(topRated),
                      const SizedBox(height: 35),
                      _buildSectionHeader("Snacks Rápidos y Saludables"),
                      const SizedBox(height: 10),
                      _buildVerticalList(quickBites),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // --- 5. SECCIÓN COMUNIDAD ---
              _buildCommunityHeader(context),
              const SizedBox(height: 15),

              FutureBuilder<List<UserRecipe>>(
                future: recipeService.fetchCommunityRecipes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyCommunity();
                  }

                  final communityRecipes = snapshot.data!;

                  return SizedBox(
                    height: 300,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 5, bottom: 20),
                      itemCount: communityRecipes.length,
                      itemBuilder: (context, index) => _buildUserRecipeCard(
                        context,
                        communityRecipes[index],
                        homeController.isAdmin, // Pasamos el flag de admin
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

  // ==========================================
  // WIDGETS DE CONSTRUCCIÓN
  // ==========================================

  Widget _buildUserRecipeCard(
    BuildContext context,
    UserRecipe recipe,
    bool isAdmin,
  ) {
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
            width: 230,
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.nutveDarkGreen,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              recipe.userName,
                              style: const TextStyle(
                                color: AppColors.nutveDarkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSmallTag(
                            Icons.access_time_filled,
                            recipe.duration,
                          ),
                          _buildSmallTag(
                            Icons.star_rounded,
                            recipe.avgRating.toStringAsFixed(1),
                            color: Colors.orange,
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

        // --- BOTÓN ELIMINAR (SOLO PARA ADMIN) ---
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
        title: const Text("Eliminar Receta"),
        content: Text("¿Deseas eliminar '${recipe.title}' de la comunidad?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminService().deleteRecipe(recipe.id, false);
              // Forzar refresco visual
              (context as Element).markNeedsBuild();
            },
            child: const Text("Confirmar Borrado"),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanelButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(colors: [Colors.black, Colors.black87]),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        icon: const Icon(Icons.psychology, color: Colors.amber),
        label: const Text(
          "CONSOLA MAESTRA (IA & AVISOS)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminControlPanelScreen()),
        ),
      ),
    );
  }

  // --- RESTO DE WIDGETS (BANNER, BUSCADOR, ETC) ---

  Widget _buildHeroBanner() {
    return Container(
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
            "Desbloquea tu \nPotencial",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.nutveDarkGreen,
            ),
            onPressed: () {},
            child: const Text(
              "MEJORAR PLAN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Buscar receta...",
          prefixIcon: const Icon(Icons.search, color: AppColors.nutveDarkGreen),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

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
            "Ver todo",
            style: TextStyle(color: AppColors.nutveSelectionGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalList(List<Recipe> recipes) {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 15),
          child: RecipeCard(recipe: recipes[index]),
        ),
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

  Widget _buildCommunityHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Comunidad kooki",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Inspírate con otros usuarios",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
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
        ),
      ],
    );
  }

  Widget _buildSmallTag(
    IconData icon,
    String text, {
    Color color = Colors.grey,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCommunity() {
    return const Center(
      child: Text(
        "¡Aún no hay recetas aquí!",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
