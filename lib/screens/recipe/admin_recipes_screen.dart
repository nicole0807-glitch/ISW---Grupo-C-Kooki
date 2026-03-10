import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
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

  // Paleta de colores consistente
  final Color bgDark = const Color(0xFF1B2521);
  final Color cardDark = const Color(0xFF24302B);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color textWhite = Colors.white;
  final Color textGrey = const Color(0xFFA1A1AA);

  ///Genera el badge visual según el estado de la receta
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.toUpperCase();

    switch (status) {
      case 'aprobado':
        bgColor = accentGreen.withOpacity(0.1);
        textColor = accentGreen;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();

    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, const Color(0xFF0F1412)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: controller.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: accentGreen),
                      )
                    : controller.recipes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: controller.recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = controller.recipes[index];
                          return _buildRecipeCard(context, controller, recipe);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accentGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Nueva Receta",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeFormScreen()),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textWhite,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            "Biblioteca de Recetas",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: accentGreen),
            onPressed: () =>
                context.read<RecipeAdminController>().loadRecipes(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, color: textGrey, size: 64),
          const SizedBox(height: 16),
          Text(
            "No hay recetas registradas",
            style: TextStyle(color: textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    RecipeAdminController controller,
    dynamic recipe,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'recipe_${recipe.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child:
                        recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: bgDark,
                            width: 70,
                            height: 70,
                            child: Icon(
                              Icons.restaurant_rounded,
                              color: textGrey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: TextStyle(
                          color: textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(recipe.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recipe.status == 'pendiente'
                                  ? "Esperando validación"
                                  : "Revisado por especialistas",
                              style: TextStyle(fontSize: 11, color: textGrey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      Icons.edit_note_rounded,
                      Colors.blueAccent,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeFormScreen(recipe: recipe),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      Icons.delete_outline_rounded,
                      Colors.redAccent,
                      () => _confirmDelete(context, controller, recipe.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onTap,
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RecipeAdminController controller,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Eliminar Receta",
          style: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "¿Estás seguro de eliminar esta receta? Esta acción afectará la base de datos pública.",
          style: TextStyle(color: textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteRecipe(id);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
