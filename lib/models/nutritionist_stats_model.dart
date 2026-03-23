/// Datos de estadísticas del nutricionista calculados desde Supabase.
class NutritionistStats {
  /// Total de recetas validadas (aprobadas + rechazadas) por el nutricionista actual.
  final int totalValidated;

  /// Recetas aprobadas.
  final int approved;

  /// Recetas rechazadas.
  final int rejected;

  /// Actividad de los últimos 7 días: conteo por día de la semana.
  /// El índice 0 = lunes de la semana actual, 6 = domingo.
  final List<int> weekdayCounts;

  NutritionistStats({
    required this.totalValidated,
    required this.approved,
    required this.rejected,
    required this.weekdayCounts,
  });

  double get approvalRatio =>
      totalValidated == 0 ? 0.0 : approved / totalValidated;

  /// Máximo de validaciones en un día de la semana (para escalar el chart).
  int get weekMax =>
      weekdayCounts.isEmpty ? 1 : weekdayCounts.reduce((a, b) => a > b ? a : b);
}
