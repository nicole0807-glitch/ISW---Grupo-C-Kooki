import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list_item.dart';
import '../models/cooking_models.dart';

class ShoppingListService {
  final _supabase = Supabase.instance.client;

  /// Inserta o actualiza los ingredientes faltantes en la tabla `shopping_list`.
  /// Maneja duplicados manualmente: si ya existe un ítem no comprado para el
  /// mismo ingrediente, actualiza la cantidad; si no, inserta uno nuevo.
  Future<void> addItems(List<MissingIngredient> items) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    if (items.isEmpty) return;

    for (final ing in items) {
      // Buscar si ya existe un ítem no comprado para este ingrediente
      final existing = await _supabase
          .from('shopping_list')
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('ingredient_id', ing.ingredientId)
          .eq('is_bought', false)
          .maybeSingle();

      if (existing != null) {
        // Actualizar cantidad
        final currentQty = (existing['quantity'] as num).toDouble();
        await _supabase
            .from('shopping_list')
            .update({'quantity': currentQty + ing.missingQuantity})
            .eq('id', existing['id']);
      } else {
        // Insertar nuevo
        await _supabase
            .from('shopping_list')
            .insert(
              ShoppingListItem(
                userId: userId,
                ingredientId: ing.ingredientId,
                quantity: ing.missingQuantity,
                unit: ing.unit,
              ).toJson(),
            );
      }
    }
  }

  /// Obtiene todos los ítems de la lista de compras del usuario actual.
  Future<List<ShoppingListItem>> getItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('shopping_list')
        .select()
        .eq('user_id', userId)
        .eq('is_bought', false)
        .order('created_at', ascending: true);

    return (response as List)
        .map((row) => ShoppingListItem.fromJson(row))
        .toList();
  }

  /// Marca un ítem como comprado.
  Future<void> markAsBought(int id) async {
    await _supabase
        .from('shopping_list')
        .update({'is_bought': true})
        .eq('id', id);
  }
}
