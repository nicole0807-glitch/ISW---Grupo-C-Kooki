import 'package:get/get.dart';
import '../models/ingredient_master.dart';
import '../data/repositories/ingredient_master_repository.dart';

/// Provider para gestionar los ingredientes maestros
class IngredientMasterProvider extends GetxController {
  final IngredientMasterRepository _repository = IngredientMasterRepository();

  var allIngredients = <IngredientMaster>[].obs;
  var filteredIngredients = <IngredientMaster>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadIngredients();
  }

  /// Cargar todos los ingredientes
  Future<void> loadIngredients() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      allIngredients.value = await _repository.fetchAllIngredients();
      filteredIngredients.value = allIngredients;

      print('✅ ${allIngredients.length} ingredientes cargados en provider');
    } catch (e) {
      errorMessage.value = e.toString();
      print('❌ Error en provider: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar ingredientes (para el autocomplete)
  void searchIngredients(String query) {
    if (query.isEmpty) {
      filteredIngredients.value = allIngredients;
      return;
    }

    filteredIngredients.value = allIngredients
        .where(
          (ingredient) =>
              ingredient.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Obtener ingrediente por ID
  IngredientMaster? getIngredientById(int id) {
    try {
      return allIngredients.firstWhere((ing) => ing.ingredientId == id);
    } catch (e) {
      return null;
    }
  }
}
