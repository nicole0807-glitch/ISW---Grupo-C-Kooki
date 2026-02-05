import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';

class PantryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Pantry';

  /// Get all ingredients for a user
  Future<List<Ingredient>> getIngredients(String user_id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user_id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar ingredientes: $e');
    }
  }

  /// Get ingredients by category
  Future<List<Ingredient>> getIngredientsByCategory(
    String user_id,
    String category,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user_id)
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al filtrar por categoría: $e');
    }
  }

  /// Add new ingredient
  Future<Ingredient> addIngredient(Ingredient ingredient) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(ingredient.toJson())
          .select()
          .single();

      // Debug: print full response from Supabase to help trace issues
      // (remove or guard these prints in production)
      print('Supabase insert response: $response');

      return Ingredient.fromJson(response);
    } catch (e) {
      print('Error en addIngredient: $e');
      rethrow;
    }
  }

  /// Update ingredient
  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _supabase
          .from(_tableName)
          .update(ingredient.toJson())
          .eq('ingredient_id', ingredient.ingredient_id!);
    } catch (e) {
      throw Exception('Error al actualizar ingrediente: $e');
    }
  }

  /// Delete ingredient
  Future<void> deleteIngredient(String ingredient_id) async {
    try {
      await _supabase.from(_tableName).delete().eq('ingredient_id', ingredient_id);
    } catch (e) {
      throw Exception('Error al eliminar ingrediente: $e');
    }
  }

  /// Search ingredients
  Future<List<Ingredient>> searchIngredients(
    String user_id,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user_id)
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Ingredient.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar: $e');
    }
  }

  /// Upload ingredient image
  Future<String?> uploadIngredientImage(
    String user_id,
    String ingredient_id,
    String imagePath,
  ) async {
    try {
      final fileName = '$user_id/$ingredient_id.jpg';
      await _supabase.storage.from('ingredient_images').upload(
            fileName,
            File(imagePath),
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage
          .from('ingredient_images')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}