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
      perfectMatches.value = _filterPerfectMatches(allRecipes, pantryItems);
    } catch (e) {
      Get.snackbar('Error', 'Hubo un problema al buscar el Partido Perfecto: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Lógica Core para evaluar los Criterios de Aceptación
  List<Recipe> _filterPerfectMatches(List<Recipe> recipes, List<Ingredient> pantry) {
    List<Recipe> matchedRecipes =[];

    for (var recipe in recipes) {
      bool isMatch = true;

      if (recipe.ingredients.isEmpty) continue;

      for (var reqIngredient in recipe.ingredients) {
        
        // Criterio 2: Buscar coincidencia de ingrediente usando nuestra función robusta
        final pantryItem = pantry.firstWhereOrNull(
          (p) => _isIngredientMatch(p.name, reqIngredient.name) 
                 // || p.ingredientId == reqIngredient.ingredientId // (RECOMENDADO PARA EL FUTURO)
        );

        if (pantryItem == null) {
          isMatch = false;
          break; 
        }

        // Criterio 3: Descartar por cantidad
        double requiredAmount = (reqIngredient.amount ?? 0).toDouble();
        double availableAmount = (pantryItem.quantity ?? 0).toDouble();

        // Normalizamos las unidades
        availableAmount = _normalizeUnitToGramsOrMl(availableAmount, pantryItem.unit);
        requiredAmount = _normalizeUnitToGramsOrMl(requiredAmount, reqIngredient.unit);

        // Agregamos un pequeñísimo margen de error por las conversiones de decimales (ej: 453.59 vs 453.6)
        if (availableAmount < (requiredAmount - 0.01)) {
          isMatch = false; 
          break;
        }
      }

      if (isMatch) {
        matchedRecipes.add(recipe);
      }
    }

    return matchedRecipes;
  }

  // =========================================================================
  // HELPER FUNCTIONS A PRUEBA DE BALAS
  // =========================================================================

  /// Normaliza un texto: minúsculas, sin acentos, sin espacios extras ni en los bordes.
  String _normalizeString(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    
    String normalized = text.toLowerCase().trim();
    
    // Eliminar dobles espacios entre palabras ("pollo   entero" -> "pollo entero")
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Reemplazar acentos/diacríticos
    normalized = normalized.replaceAll(RegExp(r'[áàäâ]'), 'a');
    normalized = normalized.replaceAll(RegExp(r'[éèëê]'), 'e');
    normalized = normalized.replaceAll(RegExp(r'[íìïî]'), 'i');
    normalized = normalized.replaceAll(RegExp(r'[óòöô]'), 'o');
    normalized = normalized.replaceAll(RegExp(r'[úùüû]'), 'u');
    
    return normalized;
  }

  /// Compara dos nombres de ingredientes de forma robusta y tolerando plurales simples.
  bool _isIngredientMatch(String? pantryName, String? recipeName) {
    if (pantryName == null || recipeName == null) return false;

    String pName = _normalizeString(pantryName);
    String rName = _normalizeString(recipeName);

    if (pName == rName) return true;

    // Tolerancia de plurales básicos (ej: "tomate" vs "tomates", "limon" vs "limones")
    if ('${pName}s' == rName || '${rName}s' == pName) return true;
    if ('${pName}es' == rName || '${rName}es' == pName) return true;

    return false;
  }

  /// Normaliza unidades abarcando múltiples formas de escribirlas (con/sin "s", abreviaciones, etc).
  double _normalizeUnitToGramsOrMl(double amount, String? unit) {
    String u = _normalizeString(unit);

    // Kilos y gramos
    if (['kg', 'kgs', 'kilo', 'kilos', 'kilogramo', 'kilogramos'].contains(u)) {
      return amount * 1000;
    }
    
    // Libras y onzas
    if (['lb', 'lbs', 'libra', 'libras'].contains(u)) {
      return amount * 453.592;
    }
    if (['oz', 'onza', 'onzas'].contains(u)) {
      return amount * 28.3495;
    }

    // Litros y mililitros
    if (['l', 'lt', 'lts', 'litro', 'litros'].contains(u)) {
      return amount * 1000;
    }

    // Volúmenes aproximados (Tazas, cucharadas)
    if (['taza', 'tazas', 'cup', 'cups', 'tz', 'tzs'].contains(u)) {
      return amount * 250; 
    }
    if (['cucharada', 'cucharadas', 'cda', 'cdas', 'tbsp'].contains(u)) {
      return amount * 15; 
    }
    if (['cucharadita', 'cucharaditas', 'cdta', 'cdt', 'tsp'].contains(u)) {
      return amount * 5; 
    }

    // Si la unidad es 'g', 'gr', 'gramo', 'gramos', 'ml', 'mililitro', 'und', 'pieza',
    // o cualquier otra cosa que no esté en la lista, asumimos que es base y devolvemos la misma cantidad.
    return amount; 
  }
}