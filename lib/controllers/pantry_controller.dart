import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/pantry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantryController extends GetxController {
  final PantryService _pantryService = PantryService();

  var allIngredients = <Ingredient>[];
  var filteredIngredients = <Ingredient>[];
  var isLoading = false.obs;
  var selectedCategory = 'Todos los ingredientes'.obs;
  var searchQuery = ''.obs;

  final List<String> categories = [
    'Todos los ingredientes',
    'Frutas y verduras',
    'Proteínas',
    'Lácteos',
    'Granos',
    'Otros',
  ];

  @override
  void onInit() {
    super.onInit();
    loadIngredients();
  }

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  /// Cargar todos los ingredientes
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
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
        'Éxito', // ← Este mensaje debería aparecer
        'Ingrediente agregado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Eliminar ingrediente por pantryId (String)
  Future<bool> deleteIngredient(String pantryId) async {
    try {
      print('🗑️ Eliminando ingrediente con pantryId: $pantryId');

      await _pantryService.deleteIngredient(pantryId);

      // Eliminar de la lista local
      allIngredients.removeWhere((item) => item.id == pantryId);
      applyFilters();

      return true;
    } catch (e) {
      print('❌ Error eliminando: $e');
      rethrow; // Lanzar la excepción para que la card la maneje
    }
  }

  /// Filtrar por categoría
  void setCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  /// Filtrar por búsqueda
  void setSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  /// Apply filters
  void applyFilters() {
    filteredIngredients = allIngredients.where((ingredient) {
      // Category filter
      final categoryMatch =
          selectedCategory.value == 'Todos los ingredientes' ||
          ingredient.category == selectedCategory.value;

      // Search filter (ahora busca en displayName)
      final searchMatch =
          searchQuery.value.isEmpty ||
          ingredient.displayName.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );

      return categoryMatch && searchMatch;
    }).toList();

    update();
  }

  /// Get total count
  int get totalItems => allIngredients.length;

  /// Clear All - Vaciar toda la despensa con confirmación
  Future<void> clearAll(BuildContext context) async {
    if (allIngredients.isEmpty) {
      Get.snackbar(
        'Info',
        'La despensa ya está vacía',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Pedir confirmación antes de eliminar todo
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar despensa'),
        content: Text(
          '¿Estás seguro? Esto eliminará los ${allIngredients.length} ingredientes de tu despensa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vaciar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading.value = true;
      await _pantryService.deleteAllIngredients(userId!);

      // Limpiar lista local
      allIngredients.clear();
      filteredIngredients.clear();
      selectedCategory.value = 'Todos los ingredientes';
      searchQuery.value = '';
      update();

      Get.snackbar(
        'Éxito',
        'Despensa vaciada correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Ingredientes que expiran pronto (para notificaciones)
  List<Ingredient> get expiringIngredients => allIngredients
      .where(
        (i) => i.expirationDate != null && (i.daysUntilExpiration ?? 99) <= 5,
      )
      .toList();

  int get expiringCount => expiringIngredients.length;
}
