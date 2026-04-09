import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cooking_models.dart';

class CookingService {
  final _supabase = Supabase.instance.client;

  // ─── Conversión de unidades a base ───────────────────────────────────────
  // Unidades de masa  → base = gramos (g)
  // Unidades de vol.  → base = mililitros (ml)
  // Unidades de pieza → base = pieza (pza / u / und) — sin conversión
  static double toBase(double quantity, String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return quantity * 1000.0;
      case 'g':
        return quantity;
      case 'l':
        return quantity * 1000.0;
      case 'ml':
        return quantity;
      default:
        return quantity; // pza, u, cda, cdta, etc. sin conversión
    }
  }

  /// Unidad canónica para el valor base (g o ml o la original)
  static String baseUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return 'g';
      case 'l':
        return 'ml';
      default:
        return unit;
    }
  }

  // ─── Validar inventario vs receta ────────────────────────────────────────
  /// Compara lo que requiere la receta contra la despensa del usuario.
  /// Devuelve [CookingValidationResult] indicando si se puede cocinar y
  /// la lista de ingredientes faltantes con la cantidad exacta que falta.
  Future<CookingValidationResult> validateInventoryForRecipe(
    int recipeId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // 1. Traer ingredientes de la receta con nombre
    final recipeIngsRaw = await _supabase
        .from('Recipe_Ingredients')
        .select('ingredient_id, amount, unit_abbreviation, Ingredient(name)')
        .eq('recipe_id', recipeId);

    // 2. Traer despensa del usuario, agregando expiration_date para validar
    final pantryRaw = await _supabase
        .from('Pantry')
        .select('ingredient_id, quantity, unit, expiration_date')
        .eq('user_id', userId);

    // Indexar despensa por ingredient_id para acceso O(1)
    final pantryMap = <int, Map<String, dynamic>>{};
    for (final row in (pantryRaw as List)) {
      pantryMap[row['ingredient_id'] as int] = row;
    }

    final List<MissingIngredient> missing = [];

    for (final ing in (recipeIngsRaw as List)) {
      final int ingredientId = ing['ingredient_id'] as int;
      final double required = toBase(
        (ing['amount'] as num).toDouble(),
        ing['unit_abbreviation'] as String? ?? 'g',
      );
      final String reqUnitBase = baseUnit(
        ing['unit_abbreviation'] as String? ?? 'g',
      );
      final ingredientName =
          (ing['Ingredient'] as Map<String, dynamic>?)?['name'] as String? ??
          'Ingrediente #$ingredientId';

      final pantryRow = pantryMap[ingredientId];

      double available = 0.0;
      if (pantryRow != null) {
        bool isExpired = false;
        final expDateStr = pantryRow['expiration_date'] as String?;
        if (expDateStr != null) {
          final expDate = DateTime.parse(expDateStr);
          if (expDate.isBefore(DateTime.now())) {
            isExpired = true;
          }
        }

        if (!isExpired) {
          available = toBase(
            (pantryRow['quantity'] as num).toDouble(),
            pantryRow['unit'] as String? ?? 'g',
          );
        }
      }

      if (available < required) {
        missing.add(
          MissingIngredient(
            ingredientId: ingredientId,
            name: ingredientName,
            missingQuantity: _formatQty(required - available, reqUnitBase),
            unit: reqUnitBase,
          ),
        );
      }
    }

    return CookingValidationResult(canCook: missing.isEmpty, missing: missing);
  }

  // ─── Ejecutar descuento atómico via RPC ──────────────────────────────────
  /// Llama a la función PostgreSQL `process_cooking_inventory` que descuenta
  /// el stock de la despensa de forma atómica y elimina filas que llegan a ≤0.
  Future<void> processCookingInventory(int recipeId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase.rpc(
      'process_cooking_inventory',
      params: {'p_recipe_id': recipeId, 'p_user_id': userId},
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  /// Redondea a 2 decimales para evitar flotantes sucios (ej: 0.30000000001)
  static double _formatQty(double value, String unit) {
    return double.parse(value.toStringAsFixed(2));
  }
}
