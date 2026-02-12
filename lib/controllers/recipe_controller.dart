import 'dart:io'; // <--- CORRECCIÓN 1: Necesario para usar "File"
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';
import 'dart:typed_data';

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
      final data = await _supabase.from('Recipes').select('''
        *,
        Recipe_Validation (
          reviewer_id,
          Profile:reviewer_id ( username )
        )
      ''').order('created_at', ascending: false);

      recipes = (data as List).map((json) {
        final recipe = Recipe.fromMap(json);
        final validations = json['Recipe_Validation'] as List?;
        if (validations != null && validations.isNotEmpty) {
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

  // CORRECCIÓN: Ahora File es reconocido gracias al import de dart:io
  Future<bool> createOrUpdateRecipe(
    Recipe recipe, {
    bool isEdit = false, 
    Uint8List? imageBytes, 
    String? fileName
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      String finalUrl = recipe.imageUrl ?? ''; // Corrección del error String?

      // Si hay bytes de imagen nuevos, subirlos
      if (imageBytes != null && fileName != null) {
        final uploadedUrl = await _service.uploadRecipeImage(imageBytes, fileName);
        if (uploadedUrl != null) finalUrl = uploadedUrl;
      }

      final recipeToSave = Recipe(
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        imageUrl: finalUrl,
        cookingTime: recipe.cookingTime,
        difficulty: recipe.difficulty,
        nutrition: recipe.nutrition,
        ingredients: recipe.ingredients,
        steps: recipe.steps,
        tagIds: recipe.tagIds,
        status: 'pendiente',
      );

      if (isEdit) {
        await _service.updateRecipe(recipeToSave);
      } else {
        await _service.createRecipe(recipeToSave);
      }
      return true;
    } catch (e) {
      print("Error en Controller: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
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