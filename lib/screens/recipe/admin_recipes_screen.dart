import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/recipe_controller.dart';
import 'recipe_form_screen.dart';

class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key});

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeAdminController>().loadRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Recetas")),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Añadir"),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.recipes.isEmpty
              ? const Center(child: Text("No hay recetas aún"))
              : ListView.builder(
                  itemCount: controller.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = controller.recipes[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(recipe.imageUrl!))
                            : const CircleAvatar(child: Icon(Icons.food_bank)),
                        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${recipe.cookingTime ?? '?'} min • ${recipe.difficulty ?? 'N/A'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeFormScreen(recipe: recipe),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, controller, recipe.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(BuildContext context, RecipeAdminController controller, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar Receta"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteRecipe(id);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}