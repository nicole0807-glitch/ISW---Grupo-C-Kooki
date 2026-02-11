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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeAdminController>().loadRecipes();
    });
  }

  ///Genera el badge visual según el estado de la receta
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.toUpperCase();

    switch (status) {
      case 'aprobado':
        bgColor = const Color(0xFF13EC5B).withOpacity(0.1);
        textColor = const Color(0xFF13EC5B);
        break;
      case 'rechazado':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case 'requiere_cambio':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = "CAMBIOS";
        break;
      default: // pendiente
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        text = "PENDIENTE";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor, 
          fontSize: 10, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text("Gestión de Recetas", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF13EC5B),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Nueva Receta", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF13EC5B)))
          : controller.recipes.isEmpty
              ? const Center(child: Text("No hay recetas registradas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = controller.recipes[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                                ? Image.network(recipe.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade200, width: 56, height: 56, child: const Icon(Icons.restaurant)),
                          ),
                          title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildStatusBadge(recipe.status),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      recipe.status == 'pendiente' 
                                          ? "Esperando validación" 
                                          : "Nutr: ${recipe.reviewerName ?? 'Asignado'}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Color(0xFF61896F)),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: recipe)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(context, controller, recipe.id),
                              ),
                            ],
                          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar Receta"),
        content: const Text("¿Estás seguro de eliminar esta receta? Esta acción afectará la base de datos pública."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteRecipe(id);
            },
            child: const Text("Confirmar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}