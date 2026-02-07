import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';

class PantryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Pantry';

  /// Get all ingredients with JOIN to master table
  Future<List<Ingredient>> getIngredients(String userId) async {
    try {
      print('🔵 Cargando ingredientes del usuario con JOIN...');
      
      // JOIN con la tabla Ingredient para traer el nombre
      final response = await _supabase
          .from(_tableName)
          .select('*, Ingredient(*)')  // ← JOIN con tabla maestra
          .eq('user_id', userId)
          .order('ingredient_id', ascending: false);

      print('🟢 Respuesta raw: $response');

      final ingredients = (response as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();

      print('🟢 ${ingredients.length} ingredientes cargados');
      return ingredients;
    } catch (e) {
      print('🔴 Error al cargar ingredientes: $e');
      throw Exception('Error al cargar ingredientes: $e');
    }
  }

  /// Add new ingredient (ahora guarda el ID del ingrediente maestro)
  Future<Ingredient> addIngredient(Ingredient ingredient) async {
    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 AGREGANDO ingrediente a Pantry');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final currentUser = _supabase.auth.currentUser;
      print('👤 Usuario: ${currentUser?.id}');
      
      final jsonData = ingredient.toJson();
      print('📦 Datos a insertar:');
      jsonData.forEach((key, value) {
        print('   $key: $value');
      });
      
      final response = await _supabase
          .from(_tableName)
          .insert(jsonData)
          .select('*, Ingredient(*)')  // ← JOIN en el INSERT también
          .single();

      print('✅ Ingrediente agregado exitosamente');
      print('📥 Respuesta: $response');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return Ingredient.fromJson(response);
      
    } on PostgrestException catch (e) {
      print('❌ PostgrestException:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      rethrow;
    } catch (e, stack) {
      print('❌ Error general: $e');
      print('Stack: $stack');
      rethrow;
    }
  }

  /// Update ingredient
  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _supabase
          .from(_tableName)
          .update(ingredient.toJson())
          .eq('ingredient_id', ingredient.pantryId!);
    } catch (e) {
      throw Exception('Error al actualizar: $e');
    }
  }

  /// Delete ingredient
  Future<void> deleteIngredient(String ingredientId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('ingredient_id', int.parse(ingredientId));
    } catch (e) {
      throw Exception('Error al eliminar: $e');
    }
  }

  /// Search ingredients
  Future<List<Ingredient>> searchIngredients(
    String userId,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*, Ingredient(*)')
          .eq('user_id', userId)
          .or('name.ilike.%$query%')
          .order('ingredient_id', ascending: false);

      return (response as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar: $e');
    }
  }
}