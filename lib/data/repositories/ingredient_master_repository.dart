import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/ingredient_master.dart';

/// Repositorio para la tabla maestra de ingredientes
class IngredientMasterRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'Ingredient';

  /// Obtener TODOS los ingredientes
  Future<List<IngredientMaster>> fetchAllIngredients() async {
    try {
      print('🔵 Cargando ingredientes ...');
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('name', ascending: true);

      final ingredients = (response as List)
          .map((item) => IngredientMaster.fromJson(item))
          .toList();

      print('🟢 ${ingredients.length} ingredientes cargados');
      return ingredients;
    } catch (e) {
      print('🔴 Error al cargar ingredientes: $e');
      throw Exception('Error al cargar ingredientes: $e');
    }
  }

  /// Buscar ingredientes por nombre (para el autocomplete)
  Future<List<IngredientMaster>> searchIngredients(String query) async {
    try {
      if (query.isEmpty) {
        return await fetchAllIngredients();
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .ilike('name', '%$query%')
          .order('name', ascending: true)
          .limit(10);

      return (response as List)
          .map((item) => IngredientMaster.fromJson(item))
          .toList();
    } catch (e) {
      print('🔴 Error en búsqueda: $e');
      throw Exception('Error en búsqueda: $e');
    }
  }

  /// Obtener un ingrediente por ID
  Future<IngredientMaster?> getIngredientById(int ingredientId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('ingredient_id', ingredientId)
          .maybeSingle();

      if (response == null) return null;
      return IngredientMaster.fromJson(response);
    } catch (e) {
      print('🔴 Error al obtener ingrediente: $e');
      return null;
    }
  }
}