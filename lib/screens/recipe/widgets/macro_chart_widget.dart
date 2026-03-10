import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/user_goal_model.dart';

class MacroChartWidget extends StatelessWidget {
  final UserGoalModel? goal;

  const MacroChartWidget({super.key, this.goal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Si no hay metas, mostramos el mensaje informativo (Criterio de Aceptación)
    if (goal == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 40,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              "No se han asignado metas aún.\nConfigura tu plan para ver tu progreso.",
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
            ),
          ],
        ),
      );
    }

    // Si hay metas, mostramos el gráfico circular
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Distribución Diaria Sugerida",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  _section(
                    goal!.targetProtein * 4,
                    "Prot",
                    Colors.blue,
                    goal!.targetCalories,
                  ),
                  _section(
                    goal!.targetCarbs * 4,
                    "Carb",
                    Colors.orange,
                    goal!.targetCalories,
                  ),
                  _section(
                    goal!.targetFat * 9,
                    "Gras",
                    Colors.red,
                    goal!.targetCalories,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(context),
          const SizedBox(height: 10),
          Text(
            "${goal!.targetCalories.toStringAsFixed(0)} kcal totales",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.green.shade400 : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _section(
    double value,
    String title,
    Color color,
    double total,
  ) {
    final double percentage = (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(
          context,
          "Prot: ${goal!.targetProtein.toStringAsFixed(0)}g",
          Colors.blue,
        ),
        _legendItem(
          context,
          "Carb: ${goal!.targetCarbs.toStringAsFixed(0)}g",
          Colors.orange,
        ),
        _legendItem(
          context,
          "Gras: ${goal!.targetFat.toStringAsFixed(0)}g",
          Colors.red,
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
