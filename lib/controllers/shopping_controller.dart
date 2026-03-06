import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/repositories/kooki_shopping_repository.dart';
import '../models/shopping_list_item.dart';
import 'pantry_controller.dart';

/// Controlador GetX para gestionar el estado del Carrito de Compras.
class ShoppingController extends GetxController {
  final KookiShoppingRepository _repository = KookiShoppingRepository();

  final cartItems = <ShoppingListItem>[].obs;
  final isLoading = false.obs;

  /// Cantidad de ítems pendientes en el carrito (para badge).
  int get cartCount => cartItems.length;

  @override
  void onInit() {
    super.onInit();
    loadCartItems();
  }

  /// Carga los ítems del carrito (is_bought = false).
  Future<void> loadCartItems() async {
    try {
      isLoading.value = true;
      final items = await _repository.fetchCartItems();
      cartItems.assignAll(items);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los ítems del carrito: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Marca un ítem como comprado y refresca la despensa.
  Future<bool> markAsBought(int cartItemId) async {
    try {
      await _repository.markAsBought(cartItemId);

      // Remover de la lista local
      cartItems.removeWhere((item) => item.id == cartItemId);

      // Refrescar la despensa automáticamente
      _refreshPantry();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo marcar como comprado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Elimina un ítem del carrito sin marcarlo como comprado.
  Future<bool> removeItem(int cartItemId) async {
    try {
      await _repository.removeItem(cartItemId);
      cartItems.removeWhere((item) => item.id == cartItemId);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el ítem: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// Limpia todos los ítems pendientes del carrito.
  Future<void> clearCartItems() async {
    try {
      await _repository.clearCartItems();
      cartItems.clear();
      Get.snackbar(
        'Éxito',
        'Carrito limpiado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo limpiar el carrito: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Refresca el PantryController si está registrado.
  void _refreshPantry() {
    try {
      final pantryController = Get.find<PantryController>();
      pantryController.loadIngredients();
    } catch (_) {
      // PantryController no está registrado, no hacer nada
    }
  }
}
