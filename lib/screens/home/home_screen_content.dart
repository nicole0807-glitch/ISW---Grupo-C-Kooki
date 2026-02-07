import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importar Provider

// Imports de tus archivos
import 'package:kooki/screens/recipe/widgets/quick_bite_card.dart';
import '../../utils/app_colors.dart';
import '../../services/recipe_service.dart';
import '../../models/recipe_model.dart';
import '../recipe/widgets/recipe_card.dart';

// 2. Importar el controlador y la pantalla de Admin
import '../../controllers/home_controller.dart'; 
import '../recipe/admin_recipes_screen.dart'; // Asegúrate que esta ruta sea correcta

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciamos el servicio de recetas
    final RecipeService recipeService = RecipeService();
    
    // 3. Escuchamos el estado del HomeController para saber si es Admin
    final homeController = context.watch<HomeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. BANNER ---
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
                  "Desbloquea tu \nPotencial",
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
                  child: const Text("MEJORAR PLAN"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 1.5 BOTÓN DE ADMIN (SOLO VISIBLE SI isAdmin es TRUE) ---
          if (homeController.isAdmin) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[900], // Color oscuro para diferenciar
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("PANEL DE ADMINISTRADOR (RECETAS)"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminRecipesScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          // -----------------------------------------------------------

          // --- 2. BARRA DE BÚSQUEDA ---
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar receta...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),

          // --- 3. SECCIÓN DE RECETAS ---
          const Text(
            "Más Populares",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          FutureBuilder<List<Recipe>>(
            future: recipeService.fetchRecipes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.nutveDarkGreen),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error al cargar recetas: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No se encontraron recetas."));
              }

              final recipes = snapshot.data!;
              final List<Recipe> topRatedRecipes = recipes.where((r) => r.rating >= 4.5).toList();
              final List<Recipe> quickBitesRecipes = recipes.where((r) => r.tagIds.contains(22)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Carrusel Horizontal de Top Rated ---
                  SizedBox(
                    height: 320,
                    child: topRatedRecipes.isEmpty
                        ? const Center(child: Text("No hay recetas destacadas aún"))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: topRatedRecipes.length,
                            itemBuilder: (context, index) {
                              return RecipeCard(recipe: topRatedRecipes[index]);
                            },
                          ),
                  ),
                  //----- QUICK HEALTHY BITES -----
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Snacks Rápidos y Saludables",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("View All", style: TextStyle(color: AppColors.nutveSelectionGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Lista Vertical de Snacks Rápidos
                  quickBitesRecipes.isEmpty
                      ? const Center(child: Text("No se encontraron snacks rápidos."))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quickBitesRecipes.length > 3 ? 3 : quickBitesRecipes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 15),
                          itemBuilder: (context, index) {
                            return QuickBiteCard(recipe: quickBitesRecipes[index]);
                          },
                        ),
                  const SizedBox(height: 50),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}