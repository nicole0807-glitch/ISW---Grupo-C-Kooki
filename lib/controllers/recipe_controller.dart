import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

class RecipeAdminController extends ChangeNotifier {
  final RecipeService _service = RecipeService();
  final _supabase = Supabase.instance.client;
  
  List<Recipe> recipes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadRecipes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
    // Hacemos un fetch que incluya la relación con la validación y el perfil del revisor
    final data = await _supabase.from('Recipes').select('''
      *,
      Recipe_Validation (
        reviewer_id,
        Profile:reviewer_id (
          username
        )
      )
    ''').order('created_at', ascending: false);

    // Mapeamos los datos incluyendo el nombre del revisor
    recipes = (data as List).map((json) {
      final recipe = Recipe.fromMap(json);
      
      // Extraemos el username del nutricionista si existe la validación
      final validations = json['Recipe_Validation'] as List?;
      if (validations != null && validations.isNotEmpty) {
        // Tomamos la última validación realizada
        final profile = validations.first['Profile'];
        recipe.reviewerName = profile != null ? profile['username'] : null;
      }
      
      return recipe;
    }).toList();

  } catch (e) {
    print('🔴 Error cargando recetas admin: $e');
  } finally {
    isLoading = false;
    notifyListeners();
  }
}


  Future<bool> createOrUpdateRecipe(Recipe recipe, {bool isEdit = false}) async {
    isLoading = true;
    notifyListeners();
    try {
      if (isEdit) {
        await _service.updateRecipe(recipe);
      } else {
        await _service.createRecipe(recipe);
      }
      await loadRecipes(); // Recargar lista actualizada
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteRecipe(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteRecipe(id);
      await loadRecipes();
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }
}