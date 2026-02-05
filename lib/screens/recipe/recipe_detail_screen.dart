import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/recipe_model.dart';


class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.nutveSelectionGreen),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
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
              background: recipe.imageUrl != null
                  ? Image.network(recipe.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[200]),
            ),
          ),

          // 2. Contenido de la Receta
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.nutveSelectionGreen, size: 20),
                      const SizedBox(width: 5),
                      const Text("4.9 (1.2k reviews)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  
                  // Perfil del Autor (Mockup según Figma)
                  const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(radius: 25, backgroundImage: NetworkImage("https://via.placeholder.com/150")),
                    title: const Text("Dr. Sarah Jenkins", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Lead Nutritionist • Premium Recipe"),
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text("FOLLOW", style: TextStyle(color: AppColors.nutveSelectionGreen, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Divider(),

                  // Stats (Duración, Costo, Dificultad)
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(Icons.schedule, "Duration", recipe.cookingTime ?? "25 mins"),
                      _buildStat(Icons.payments, "Cost", "Low"),
                      _buildStat(Icons.fitness_center, "Difficulty", recipe.difficulty ?? "Easy"),
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
                        Tab(text: "Ingredients"),
                        Tab(text: "Instructions"),
                        Tab(text: "Nutrition"),
                      ],
                    ),
                  ),

                  // Lista de Ingredientes
                  const SizedBox(height: 20),
                  Text("Ingredients for 2 servings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  ...recipe.ingredients.map((ing) => _buildIngredientItem(ing)),

                  // Pasos (Instructions)
                  const SizedBox(height: 40),
                  const Text("Step-by-Step", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...recipe.steps.asMap().entries.map((entry) => _buildStepItem(entry.key + 1, entry.value)),
                  
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
        color: Colors.white.withOpacity(0.9),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.nutveSelectionGreen,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () {},
          child: const Text("START COOKING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Text("${ing.amount} ${ing.unit}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
            child: Text("$number", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(instruction, style: const TextStyle(height: 1.5, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}