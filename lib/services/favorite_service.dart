import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> fetchFavoriteIds(String userId) async {
    try {
      final response = await _supabase
          .from('user_favorites')
          .select('recipe_id')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => item['recipe_id'].toString())
          .toList();
    } on PostgrestException catch (pgE) {
      if (pgE.code == '42P01') {
        print(
          '❌ [ERROR]: La tabla "user_favorites" no existe. Por favor, ejecuta el SQL de creación en Supabase.',
        );
      } else {
        print('Error fetching favorites PG: ${pgE.message}');
      }
      return [];
    } catch (e) {
      print('Error fetching favorites from Supabase: $e');
      return [];
    }
  }

  Future<void> addFavorite(String userId, dynamic recipeId) async {
    try {
      await _supabase.from('user_favorites').upsert({
        'user_id': userId,
        'recipe_id': recipeId.toString(),
      });
    } on PostgrestException catch (pgE) {
      if (pgE.code == '42P01') {
        print('❌ [ERROR]: La tabla "user_favorites" no existe.');
        throw Exception(
          'Error en el servidor: Falta configurar la tabla de favoritos en Supabase.',
        );
      }
      throw Exception('Error al guardar favorito: ${pgE.message}');
    } catch (e) {
      print('Error adding favorite to Supabase: $e');
      throw Exception('No se pudo guardar la receta en favoritos');
    }
  }

  Future<void> removeFavorite(String userId, dynamic recipeId) async {
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId.toString());
    } catch (e) {
      print('Error removing favorite from Supabase: $e');
      throw Exception('No se pudo eliminar la receta de favoritos');
    }
  }
}
