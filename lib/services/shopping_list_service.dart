import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list_item.dart';
import '../models/cooking_models.dart';

class ShoppingListService {
  final _supabase = Supabase.instance.client;

  /// Inserta o actualiza los ingredientes faltantes en la tabla `shopping_list`.
  /// Usa upsert con conflicto en (user_id, ingredient_id) para evitar duplicados.
  Future<void> addItems(List<MissingIngredient> items) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');
    if (items.isEmpty) return;

    final rows = items
        .map(
          (ing) => ShoppingListItem(
            userId: userId,
            ingredientId: ing.ingredientId,
            quantity: ing.missingQuantity,
            unit: ing.unit,
          ).toJson(),
        )
        .toList();

    await _supabase
        .from('shopping_list')
        .upsert(rows, onConflict: 'user_id,ingredient_id');
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
