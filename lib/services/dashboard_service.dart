import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  // 4. Datos para el gráfico: Usuarios creados en los últimos 7 días
  Future<List<Map<String, dynamic>>> getWeeklyRegistrations() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Formato ISO para Supabase
    final String formattedDate = DateFormat("yyyy-MM-ddTHH:mm:ss").format(sevenDaysAgo);

    final response = await _supabase
        .from('Profile')
        .select('created_at')
        .gte('created_at', formattedDate); // Mayor o igual a hace 7 días
        
    return List<Map<String, dynamic>>.from(response);
  }

  // 5. Actividad Reciente (Mezcla de Validaciones y Recetas)
  // Traemos las últimas validaciones hechas
  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final response = await _supabase
        .from('Recipe_Validation')
        .select('created_at, review_notes, check_nutritional_accuracy, Recipes(title), Profile(username)')
        .order('created_at', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(response);
  }
}