import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';
import '../models/recipe_validation_model.dart';

class RecipeValidationService {
  final _supabase = Supabase.instance.client;

  /// Obtiene solo las recetas con estado 'pendiente' para la cola del nutricionista
  Future<List<Recipe>> fetchPendingRecipes() async {
    try {
      final response = await _supabase
          .from('Recipes')
          .select('''
            *,
            Recipe_Steps (*),
            Recipe_Tags (*),
            Recipe_Ingredients (
              *,
              Ingredient (name)
            )
          ''')
          .eq('status', 'pendiente')
          .order('created_at', ascending: true);

      return (response as List).map((json) => Recipe.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar cola de validación: $e');
    }
  }

  /// Obtiene el conteo de recetas revisadas por el usuario actual el día de hoy
  Future<int> getReviewedTodayCount() async {
  try {
    final String userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    // La clave es capturar el PostgrestResponse completo
    final response = await _supabase
        .from('Recipe_Validation')
        .select('*') // Pedimos el conteo exacto
        .eq('reviewer_id', userId)
        .gte('created_at', todayStart);

    // En las versiones nuevas, el conteo viene en la propiedad 'count' del objeto de respuesta
    final List<dynamic> data = response as List<dynamic>;
    return data.length; 
  } catch (e) {
    print('Error al obtener conteo diario: $e');
    return 0;
  }
}

  /// Procesa la validación: Inserta en Recipe_Validation y actualiza Recipes.status
  Future<void> submitValidation({
    required RecipeValidation validation,
    required String newStatus,
  }) async {
    try {
      // 1. Guardar el detalle de la revisión (Checklist + Notas)
      await _supabase.from('Recipe_Validation').insert(validation.toJson());

      // 2. Actualizar el estado de la receta principal
      final updateResponse = await _supabase
          .from('Recipes')
          .update({'status': newStatus})
          .eq('id', validation.recipeId)
          .select(); // El select() nos ayuda a verificar si realmente se alteró algo
          
    if (updateResponse.isEmpty) {
      print("⚠️ Alerta: No se encontró la receta con ID ${validation.recipeId} para actualizar.");
    } else {
      print("✅ Receta ${validation.recipeId} actualizada a: $newStatus");
    }
        
  } catch (e) {
    print("🔴 Error crítico en submitValidation: $e");
    throw Exception('Error al procesar la validación: $e');
  }
}
}