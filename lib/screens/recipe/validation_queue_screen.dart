import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_validation_service.dart';
import '../../widgets/kooki_remote_image.dart';
import 'review_recipe_screen.dart';

class ValidationQueueScreen extends StatefulWidget {
  const ValidationQueueScreen({super.key});

  @override
  State<ValidationQueueScreen> createState() => _ValidationQueueScreenState();
}

class _ValidationQueueScreenState extends State<ValidationQueueScreen> {
  final RecipeValidationService _service = RecipeValidationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Cola de Validación",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<dynamic>>(
      // Recarga los datos cada vez que se llama a setState
      future: Future.wait([
        _service.fetchPendingRecipes(),
        _service.getReviewedTodayCount(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF13EC5B)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final List<Recipe> recipes = snapshot.data![0] as List<Recipe>;
        final int reviewedCount = snapshot.data![1] as int;

        final priorityRecipes = recipes.take(2).toList();
        final recentRecipes = recipes.skip(2).toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(recipes.length, reviewedCount),
                _buildSearchBar(),
                _buildSectionHeader("Cola Prioritaria", isHighPriority: true),

                if (recipes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text("No hay recetas pendientes de validación"),
                    ),
                  ),

                ...priorityRecipes.map(
                  (r) => _buildRecipeItem(r, isPriority: true),
                ),
                _buildSectionHeader("Envíos Recientes"),
                ...recentRecipes.map(
                  (r) => _buildRecipeItem(r, isPriority: false),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(int pendingCount, int reviewedToday) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatCard("Pendientes", pendingCount.toString()),
          const SizedBox(width: 16),
          _buildStatCard("Revisadas Hoy", reviewedToday.toString()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Buscar por receta o autor",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool isHighPriority = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (isHighPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF13EC5B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Alta Prioridad",
                style: TextStyle(
                  color: Color(0xFF13EC5B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(Recipe recipe, {required bool isPriority}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: KookiRemoteImage(
              imageUrl: recipe.imageUrl,
              bucketHint: 'recipe_images',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: Container(color: Colors.grey, width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  recipe.reviewerName != null
                      ? 'por ${recipe.reviewerName}'
                      : 'Kooki Chef',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPriority
                  ? const Color(0xFF13EC5B)
                  : const Color(0xFF13EC5B).withOpacity(0.1),
              foregroundColor: isPriority
                  ? Colors.black
                  : const Color(0xFF13EC5B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // CAMBIO CLAVE: Esperar el resultado de la pantalla de revisión
              final bool? wasReviewed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewRecipeScreen(recipe: recipe),
                ),
              );

              // Si se validó con éxito, refrescamos la lista y contadores
              if (wasReviewed == true) {
                setState(() {});
              }
            },
            child: const Text(
              "Revisar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return const SizedBox.shrink();
  }
}
