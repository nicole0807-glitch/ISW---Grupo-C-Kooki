import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Obtener usuarios activos (Tabla Profile)
  Future<int> getActiveUsersCount() async {
    final response = await _supabase
        .from('Profile')
        .count(CountOption.exact)
        .eq('status', true); // Asumiendo que status=true es activo
    return response;
  }

  // 2. Obtener recetas pendientes (Tabla Recipes)
  Future<int> getPendingRecipesCount() async {
    final response = await _supabase
        .from('Recipes')
        .count(CountOption.exact)
        .eq('status', 'pendiente');
    return response;
  }

  // 3. Obtener nuevos reportes (Usando tabla notifications como ejemplo)
  Future<int> getNewReportsCount() async {
    // Si tienes un tipo específico de notificación para reportes, agrégalo al filtro
    final response = await _supabase
        .from('notifications')
        .count(CountOption.exact);
    return response;
  }

  Future<List<Map<String, dynamic>>> getWeeklyRegistrations() async {
    // La tabla Profile original no tiene 'created_at'.
    // Para evitar errores (PostgrestException 42703), devolvemos lista vacía temporalmente
    // hasta que el backend (Supabase) provea el campo creado_en o se consulte la tabla auth.users.
    return [];
  }

  // 5. Actividad Reciente (Mezcla de Validaciones y Recetas)
  // Traemos las últimas validaciones hechas
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final response = await _supabase
        .from('Recipe_Validation')
        .select(
          'created_at, review_notes, check_nutritional_accuracy, Recipes(title), Profile(username)',
        )
        .order('created_at', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(response);
  }
}
