import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe_model.dart';
import '../models/ingredient.dart';
import '../services/recipe_service.dart';
import '../services/pantry_service.dart';

class PerfectMatchController extends GetxController {
  final RecipeService _recipeService = RecipeService();
  final PantryService _pantryService = PantryService();

  var perfectMatches = <Recipe>[].obs;
  var closeMatches = <Recipe>[].obs; // <-- NUEVA LISTA PARA COINCIDENCIA CERCANA
  var isLoading = false.obs;

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    findPerfectMatches();
  }

  Future<void> findPerfectMatches() async {
    if (userId == null) {
      Get.snackbar('Error', 'Debes estar registrado (Criterio 1)');
      return;
    }

    try {
      isLoading.value = true;
      final List<Ingredient> pantryItems = await _pantryService.getIngredients(userId!);
      final List<Recipe> allRecipes = await _recipeService.fetchRecipes(onlyApproved: true);
      
      // Llamamos a la nueva función que categoriza ambas listas
      _categorizeMatches(allRecipes, pantryItems);
    } catch (e) {
      Get.snackbar('Error', 'Hubo un problema al buscar coincidencias: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Categoriza las recetas en "Perfectas" (0 faltantes) o "Cercanas" (1 o 2 faltantes)
  void _categorizeMatches(List<Recipe> recipes, List<Ingredient> pantry) {
    List<Recipe> exact = [];
    List<Recipe> close =[];

    for (var recipe in recipes) {
      if (recipe.ingredients.isEmpty) continue;

      int missingCount = 0; // Contador de ingredientes faltantes

      for (var reqIngredient in recipe.ingredients) {
        final pantryItem = pantry.firstWhereOrNull(
          (p) => _isIngredientMatch(p.name, reqIngredient.name)
        );

        // Si no lo tiene en absoluto, suma 1 a los faltantes
        if (pantryItem == null) {
          missingCount++;
          continue; 
        }

        double requiredAmount = (reqIngredient.amount ?? 0).toDouble();
        double availableAmount = (pantryItem.quantity ?? 0).toDouble();

        availableAmount = _normalizeUnitToGramsOrMl(availableAmount, pantryItem.unit);
        requiredAmount = _normalizeUnitToGramsOrMl(requiredAmount, reqIngredient.unit);

        // Si lo tiene pero no le alcanza la cantidad, también suma 1 a los faltantes
        if (availableAmount < (requiredAmount - 0.01)) {
          missingCount++;
        }
      }

      // Clasificamos según los ingredientes que le falten
      if (missingCount == 0) {
        exact.add(recipe);
      } else if (missingCount > 0 && missingCount <= 2) {
        close.add(recipe);
      }
    }

    perfectMatches.value = exact;
    closeMatches.value = close;
  }

  // =========================================================================
  // HELPER FUNCTIONS 
  // =========================================================================

  String _normalizeString(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    
    String normalized = text.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'[áàäâ]'), 'a');
    normalized = normalized.replaceAll(RegExp(r'[éèëê]'), 'e');
    normalized = normalized.replaceAll(RegExp(r'[íìïî]'), 'i');
    normalized = normalized.replaceAll(RegExp(r'[óòöô]'), 'o');
    normalized = normalized.replaceAll(RegExp(r'[úùüû]'), 'u');
    
    return normalized;
  }

  bool _isIngredientMatch(String? pantryName, String? recipeName) {
    if (pantryName == null || recipeName == null) return false;

    String pName = _normalizeString(pantryName);
    String rName = _normalizeString(recipeName);

    if (pName == rName) return true;

    if ('${pName}s' == rName || '${rName}s' == pName) return true;
    if ('${pName}es' == rName || '${rName}es' == pName) return true;

    return false;
  }

  double _normalizeUnitToGramsOrMl(double amount, String? unit) {
    String u = _normalizeString(unit);

    if (['kg', 'kgs', 'kilo', 'kilos', 'kilogramo', 'kilogramos'].contains(u)) {
      return amount * 1000;
    }
    if (['lb', 'lbs', 'libra', 'libras'].contains(u)) {
      return amount * 453.592;
    }
    if (['oz', 'onza', 'onzas'].contains(u)) {
      return amount * 28.3495;
    }
    if (['l', 'lt', 'lts', 'litro', 'litros'].contains(u)) {
      return amount * 1000;
    }
    if (['taza', 'tazas', 'cup', 'cups', 'tz', 'tzs'].contains(u)) {
      return amount * 250; 
    }
    if (['cucharada', 'cucharadas', 'cda', 'cdas', 'tbsp'].contains(u)) {
      return amount * 15; 
    }
    if (['cucharadita', 'cucharaditas', 'cdta', 'cdt', 'tsp'].contains(u)) {
      return amount * 5; 
    }
    return amount; 
  }
}