import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/pantry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';

class PantryController extends GetxController {
  final PantryService _pantryService = PantryService();

  var allIngredients = <Ingredient>[].obs;
  var filteredIngredients = <Ingredient>[].obs;
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
    // Listen to Auth State changes to load ingredients as soon as user is ready
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        print(
          'PantryController: Auth change detected ($event). Loading ingredients...',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadIngredients(showError: false);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadIngredients(showError: false);
    });
  }

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  /// Cargar todos los ingredientes
  Future<void> loadIngredients({bool showError = true}) async {
    if (userId == null) return;

    try {
      isLoading.value = true;
      
      // Limpieza silenciosa de ingredientes expirados (más de 7 días)
      await _pantryService.deleteOldExpiredIngredients(userId!);

      allIngredients.assignAll(await _pantryService.getIngredients(userId!));
      applyFilters();
    } catch (e) {
      debugPrint('Error loading ingredients: $e');
      if (showError) _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleError(dynamic e) {
    String message = e.toString();
    if (message.contains('SocketException') ||
        message.contains('ClientException') ||
        message.contains('Network') ||
        message.contains('Failed host lookup')) {
      message = 'Error de conexión. Verifica tu internet.';
    } else {
      message = 'No se pudo completar la operación.';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'Aviso',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.nutveSelectionGreen.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      );
    });
  }

  /// Add new ingredient
  Future<bool> addIngredient(Ingredient ingredient) async {
    try {
      isLoading.value = true;

      // 1. Detectar si esto es una sustitución por caducidad
      final existingIndex = allIngredients.indexWhere(
        (i) => i.ingredientMasterId == ingredient.ingredientMasterId && i.isExpired
      );
      final isReplacement = existingIndex != -1;

      // 2. Insertar en BDD (El Trigger de Supabase borrará silenciosamente el viejo)
      final newIngredient = await _pantryService.addIngredient(ingredient);

      // 3. UI y Efectos Visuales
      if (isReplacement) {
        // Remueve el expirado antiguo para no tener duplicado visual
        allIngredients.removeAt(existingIndex);
        
        // Simulación rápida de refresh para "flashear" la lista
        isLoading.value = false;
        await Future.delayed(const Duration(milliseconds: 50));
        isLoading.value = true;
        await Future.delayed(const Duration(milliseconds: 200));

        allIngredients.insert(0, newIngredient);
        applyFilters();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            '🔄 Sustitución Automática',
            'Hemos reemplazado tu ingrediente vencido por uno fresco',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(10),
            borderRadius: 8,
          );
        });
      } else {
        // Inserción normal
        allIngredients.insert(0, newIngredient);
        applyFilters();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Éxito',
            'Ingrediente agregado correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF4CAF50),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(10),
            borderRadius: 8,
          );
        });
      }

      return true;
    } catch (e) {
      _handleError(e);
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Éxito',
          'Ingrediente actualizado',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      return true;
    } catch (e) {
      _handleError(e);
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
    filteredIngredients.assignAll(
      allIngredients.where((ingredient) {
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
      }).toList(),
    );
  }

  /// Get total count
  int get totalItems => allIngredients.length;

  /// Clear All - Vaciar toda la despensa con confirmación
  Future<void> clearAll(BuildContext context) async {
    if (allIngredients.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Info',
          'La despensa ya está vacía',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
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
      selectedCategory.value = 'Todos los ingredientes';
      searchQuery.value = '';
      applyFilters();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Éxito',
          'Despensa vaciada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
        );
      });
    } catch (e) {
      _handleError(e);
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
