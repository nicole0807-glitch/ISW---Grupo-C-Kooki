import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final _supabase = Supabase.instance.client;

 Future<List<Recipe>> fetchRecipes() async {
  try {
   final response = await _supabase.from('Recipes').select('''
      *,
      "Recipe_Ingredients" (
        amount,
        unit_abbreviation,
        "Ingredient" ( name )
      ),
      "Recipe_Steps" (
        step_order,
        instruction
      ),
      "Recipe_Tags" (
        tag_id
      )
    ''').eq('is_validated', true);

    print("PRUEBA - Recetas encontradas: ${(response as List).length}");
    return (response as List).map((data) => Recipe.fromMap(data)).toList();
  } catch (e) {
    print("Error detallado: $e");
    throw Exception('Error al cargar recetas: $e');
  }
}
}