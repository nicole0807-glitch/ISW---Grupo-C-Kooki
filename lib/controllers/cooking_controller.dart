import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/cooking_models.dart';
import '../services/cooking_service.dart';
import '../services/shopping_list_service.dart';
import './pantry_controller.dart';

class CookingController extends GetxController {
  final CookingService _cookingService = CookingService();
  final ShoppingListService _shoppingListService = ShoppingListService();

  // Observables para el estado de la UI
  var isValidating = false.obs;
  var isCooking = false.obs;
  var isAddingToCart = false.obs;

  // Resultado de la última validación
  var validationResult = Rx<CookingValidationResult?>(null);

  /// Valida si el usuario tiene todos los ingredientes necesarios en su despensa.
  Future<CookingValidationResult?> validateInventory(int recipeId) async {
    try {
      isValidating.value = true;
      final result = await _cookingService.validateInventoryForRecipe(recipeId);
      validationResult.value = result;
      return result;
    } catch (e) {
      Get.snackbar(
        'Error de Validación',
        'No se pudo verificar el inventario: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isValidating.value = false;
    }
  }

  /// Ejecuta el descuento de inventario en la base de datos (RPC).
  /// Solo se debe llamar si la validación fue exitosa (canCook == true).
  Future<bool> startCooking(int recipeId) async {
    try {
      isCooking.value = true;

      // Ejecutar descuento atómico en Supabase
      await _cookingService.processCookingInventory(recipeId);

      // Refrescar el PantryController para que la UI de la despensa se actualice
      if (Get.isRegistered<PantryController>()) {
        await Get.find<PantryController>().loadIngredients();
      }

      Get.snackbar(
        '¡A cocinar! 🍳',
        'El inventario ha sido descontado correctamente.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF52B788), // nutveSelectionGreen
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error al Cocinar',
        'Hubo un problema al descontar el inventario: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isCooking.value = false;
    }
  }

  /// Agrega los ingredientes seleccionados a la lista de compras.
  Future<bool> addToShoppingList(List<MissingIngredient> items) async {
    if (items.isEmpty) return false;

    try {
      isAddingToCart.value = true;
      await _shoppingListService.addItems(items);

      Get.snackbar(
        'Lista de Compras 🛒',
        'Se han agregado ${items.length} ingredientes a tu lista.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF52B788),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron agregar los ítems a la lista: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isAddingToCart.value = false;
    }
  }
}
