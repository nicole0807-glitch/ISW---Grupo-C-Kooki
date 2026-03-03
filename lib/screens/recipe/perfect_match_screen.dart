import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/perfect_match_controller.dart';

class PerfectMatchScreen extends StatelessWidget {
  PerfectMatchScreen({Key? key}) : super(key: key);

  final PerfectMatchController controller = Get.put(PerfectMatchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partido Perfecto'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.perfectMatches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No hay "Partidos Perfectos".\nIntenta agregar más ingredientes a tu despensa o comprar lo que te falta para otras recetas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.perfectMatches.length,
          itemBuilder: (context, index) {
            final recipe = controller.perfectMatches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: recipe.imageUrl != null
                    ? Image.network(recipe.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.fastfood, size: 50),
                title: Text(recipe.title),
                subtitle: Text('Dificultad: ${recipe.difficulty} • ⏱️ ${recipe.cookingTime}'),
                trailing: const Icon(Icons.chevron_right, color: Colors.green),
                onTap: () {
                  // Navegar al detalle de la receta
                  // Get.to(() => RecipeDetailScreen(recipe: recipe));
                },
              ),
            );
          },
        );
      }),
    );
  }
}