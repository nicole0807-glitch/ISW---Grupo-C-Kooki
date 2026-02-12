import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

class RecipeAdminController extends ChangeNotifier {
  final RecipeService _service = RecipeService();

  List<Recipe> recipes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadRecipes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      recipes = await _service.fetchRecipes();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrUpdateRecipe(
    Recipe recipe, {
    bool isEdit = false,
  }) async {
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
