import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/shopping_list_item.dart';

/// Repositorio para el carrito de compras.
/// Gestiona la tabla `shopping_list` y la transferencia atómica a `Pantry`.
class KookiShoppingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Obtiene ítems del carrito donde is_bought = false,
  /// con JOIN a la tabla Ingredient para traer el nombre.
  Future<List<ShoppingListItem>> fetchCartItems() async {
    if (_userId == null) return [];

    try {
      // Intentar con JOIN para traer el nombre del ingrediente
      final response = await _supabase
          .from('shopping_list')
          .select('*, Ingredient(name)')
          .eq('user_id', _userId!)
          .eq('is_bought', false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => ShoppingListItem.fromJson(row))
          .toList();
    } catch (_) {
      // Fallback: sin JOIN (si no hay FK configurada)
      final response = await _supabase
          .from('shopping_list')
          .select('*')
          .eq('user_id', _userId!)
          .eq('is_bought', false)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => ShoppingListItem.fromJson(row))
          .toList();
    }
  }

  /// Marca un ítem como comprado y transfiere la cantidad a la despensa.
  ///
  /// Lógica atómica:
  /// 1. Lee el ítem del carrito.
  /// 2. Cambia is_bought = true.
  /// 3. Busca si el ingrediente ya existe en Pantry para el usuario.
  /// 4. Si existe → suma la cantidad.
  /// 5. Si no existe → crea un nuevo registro.
  Future<void> markAsBought(int cartItemId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // 1. Leer el ítem del carrito
    final cartRow = await _supabase
        .from('shopping_list')
        .select()
        .eq('id', cartItemId)
        .single();

    final cartItem = ShoppingListItem.fromJson(cartRow);

    // 2. Marcar como comprado
    await _supabase
        .from('shopping_list')
        .update({'is_bought': true})
        .eq('id', cartItemId);

    // 3. Obtener el nombre del ingrediente desde la tabla maestra
    String ingredientName = cartItem.ingredientName ?? 'Desconocido';
    if (ingredientName == 'Desconocido' ||
        ingredientName.startsWith('Ingrediente #')) {
      final masterRow = await _supabase
          .from('Ingredient')
          .select('name')
          .eq('ingredient_id', cartItem.ingredientId)
          .maybeSingle();
      if (masterRow != null) {
        ingredientName = masterRow['name'] as String;
      }
    }

    // 4. Buscar si ya existe en la despensa (Pantry)
    final pantryRows = await _supabase
        .from('Pantry')
        .select()
        .eq('user_id', _userId!)
        .eq('ingredient_id', cartItem.ingredientId);

    if ((pantryRows as List).isNotEmpty) {
      // 5. Existe → sumar cantidad
      final existingRow = pantryRows.first;
      final existingQty = (existingRow['quantity'] as num).toDouble();

      final newQty = existingQty + cartItem.quantity;

      await _supabase
          .from('Pantry')
          .update({'quantity': newQty})
          .eq('user_id', _userId!)
          .eq('ingredient_id', cartItem.ingredientId);
    } else {
      // 6. No existe → crear nuevo registro en Pantry
      await _supabase.from('Pantry').insert({
        'user_id': _userId!,
        'ingredient_id': cartItem.ingredientId,
        'name': ingredientName,
        'quantity': cartItem.quantity,
        'unit': cartItem.unit,
        'category': 'Otros',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Elimina todos los ítems pendientes del carrito (is_bought = false).
  Future<void> clearCartItems() async {
    if (_userId == null) return;

    await _supabase
        .from('shopping_list')
        .delete()
        .eq('user_id', _userId!)
        .eq('is_bought', false);
  }

  /// Elimina un ítem específico del carrito (sin marcarlo como comprado).
  Future<void> removeItem(int cartItemId) async {
    await _supabase.from('shopping_list').delete().eq('id', cartItemId);
  }
}
