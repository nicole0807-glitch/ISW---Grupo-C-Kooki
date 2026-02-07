import 'package:get/get.dart';
import '../models/ingredient.dart';
import '../services/pantry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantryController extends GetxController {
  final PantryService _pantryService = PantryService();
  
  var allIngredients = <Ingredient>[];
  var filteredIngredients = <Ingredient>[];
  var isLoading = false.obs;
  var selectedCategory = 'All Items'.obs;
  var searchQuery = ''.obs;

  final List<String> categories = [
    'All Items',
    'Vegetables',
    'Protein',
    'Dairy',
    'Grains',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    loadIngredients();
  }

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  /// Load all ingredients
  Future<void> loadIngredients() async {
    if (userId == null) return;

    try {
      isLoading.value = true;
      allIngredients = await _pantryService.getIngredients(userId!);
      applyFilters();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new ingredient
  Future<bool> addIngredient(Ingredient ingredient) async {
    try {
      isLoading.value = true;
      final newIngredient = await _pantryService.addIngredient(ingredient);
      allIngredients.insert(0, newIngredient);
      applyFilters();
      
      Get.snackbar(
        'Éxito',
        'Ingrediente agregado correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update ingredient
  Future<bool> updateIngredient(Ingredient ingredient) async {
    try {
      isLoading.value = true;
      await _pantryService.updateIngredient(ingredient);
      
      final index = allIngredients.indexWhere((i) => i.id == ingredient.id);
      if (index != -1) {
        allIngredients[index] = ingredient;
        applyFilters();
      }
      
      Get.snackbar(
        'Éxito',
        'Ingrediente actualizado',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete ingredient
  Future<bool> deleteIngredient(String ingredientId) async {
    try {
      await _pantryService.deleteIngredient(ingredientId);
      allIngredients.removeWhere((item) => item.ingredientId == ingredientId);
      applyFilters();
      
      Get.snackbar(
        'Éxito',
        'Ingrediente eliminado',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Set category filter
  void setCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  /// Apply filters
  void applyFilters() {
    filteredIngredients = allIngredients.where((ingredient) {
      // Category filter
      final categoryMatch = selectedCategory.value == 'All Items' ||
          ingredient.category == selectedCategory.value;

      // Search filter (ahora busca en displayName)
      final searchMatch = searchQuery.value.isEmpty ||
          ingredient.displayName
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());

      return categoryMatch && searchMatch;
    }).toList();

    update();
  }

  /// Get total count
  int get totalItems => allIngredients.length;

  /// Clear all filters
  void clearFilters() {
    selectedCategory.value = 'All Items';
    searchQuery.value = '';
    applyFilters();
  }
}