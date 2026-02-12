import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/dashboard_service.dart';

class AdminDashboardController extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  // Estados
  bool isLoading = true;
  String errorMessage = '';

  // Variables de datos
  String activeUsers = "0";
  int newReports = 0;
  int pendingQueue = 0;
  int newRegistrationsCount = 0; // Total de la semana
  
  // Datos del gráfico (Lun-Dom)
  List<double> weeklyData = [0, 0, 0, 0, 0, 0, 0];
  
  // Lista de actividad reciente
  List<Map<String, String>> recentActivities = [];

  AdminDashboardController() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading = true;
    notifyListeners();

    try {
      // Ejecutamos todas las promesas en paralelo para mayor velocidad
      final results = await Future.wait([
        _service.getActiveUsersCount(),
        _service.getPendingRecipesCount(),
        _service.getNewReportsCount(),
        _service.getWeeklyRegistrations(),
        _service.getRecentActivity(),
      ]);

      // 1. Asignar contadores simples
      final int usersCount = results[0] as int;
      activeUsers = _formatNumber(usersCount); // Formato "12.4k"
      
      pendingQueue = results[1] as int;
      newReports = results[2] as int;

      // 2. Procesar Gráfico Semanal
      final registrations = results[3] as List<Map<String, dynamic>>;
      _processWeeklyChart(registrations);

      // 3. Procesar Actividad Reciente
      final rawActivity = results[4] as List<Map<String, dynamic>>;
      _processRecentActivity(rawActivity);

      errorMessage = '';
    } catch (e) {
      errorMessage = "Error cargando datos: $e";
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Lógica para agrupar registros por día de la semana (Lunes = index 0)
  void _processWeeklyChart(List<Map<String, dynamic>> data) {
    List<double> tempWeek = [0, 0, 0, 0, 0, 0, 0];
    newRegistrationsCount = data.length;

    for (var item in data) {
      if (item['created_at'] != null) {
        // Supabase suele devolver fechas en UTC ISO 8601
        DateTime date = DateTime.parse(item['created_at']).toLocal();
        // weekday devuelve 1 (Lunes) a 7 (Domingo). Restamos 1 para índice 0-6
        int dayIndex = date.weekday - 1; 
        if (dayIndex >= 0 && dayIndex < 7) {
          tempWeek[dayIndex]++;
        }
      }
    }
    weeklyData = tempWeek;
  }

  // Formatear la actividad cruda de Supabase para la UI
  void _processRecentActivity(List<Map<String, dynamic>> data) {
    recentActivities = data.map((item) {
      // 1. Hacemos un CAST explícito para decirle a Dart: 
      // "Oye, esto que viene de la base de datos es un Mapa, no cualquier cosa".
      final recipeData = item['Recipes'] as Map<String, dynamic>?;
      final profileData = item['Profile'] as Map<String, dynamic>?;

      // 2. Extraemos los valores y usamos .toString() para asegurar que sean String
      // Esto evita el error de tipo.
      final recipeTitle = recipeData?['title']?.toString() ?? 'Receta desconocida';
      final reviewer = profileData?['username']?.toString() ?? 'Usuario';
      
      // Manejo seguro de la fecha
      final dateStr = item['created_at']?.toString();
      final date = dateStr != null 
          ? DateTime.parse(dateStr).toLocal() 
          : DateTime.now();
          
      final timeAgo = _getTimeAgo(date);

      // 3. Retornamos explícitamente un Map<String, String>
      // Al poner <String, String> antes de las llaves, forzamos el tipo.
      return <String, String>{
        "initial": reviewer.isNotEmpty ? reviewer[0].toUpperCase() : "?",
        "action": "Revisó receta",
        "target": recipeTitle,
        "time": timeAgo,
        "type": "review"
      };
    }).toList();
  }
  // Utilidad para formatear números (ej: 1200 -> 1.2k)
  String _formatNumber(int number) {
    if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}k";
    }
    return number.toString();
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }
}