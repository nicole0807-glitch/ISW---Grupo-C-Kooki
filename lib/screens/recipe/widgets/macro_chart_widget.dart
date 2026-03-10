import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/user_goal_model.dart';

class MacroChartWidget extends StatelessWidget {
  final UserGoalModel? goal;

  const MacroChartWidget({super.key, this.goal});

  @override
  Widget build(BuildContext context) {
    // Si no hay metas, mostramos el mensaje informativo (Criterio de Aceptación)
    if (goal == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column( // Quitamos el 'const' de aquí para evitar el error de la imagen
          children: [
            Icon(Icons.analytics_outlined, size: 40, color: Colors.grey), // Corregido minúscula
            const SizedBox(height: 10),
            const Text(
              "No se han asignado metas aún.\nConfigura tu plan para ver tu progreso.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Si hay metas, mostramos el gráfico circular
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Distribución Diaria Sugerida",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  _section(goal!.targetProtein * 4, "Prot", Colors.blue, goal!.targetCalories),
                  _section(goal!.targetCarbs * 4, "Carb", Colors.orange, goal!.targetCalories),
                  _section(goal!.targetFat * 9, "Gras", Colors.red, goal!.targetCalories),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
          const SizedBox(height: 10),
          Text(
            "${goal!.targetCalories.toStringAsFixed(0)} kcal totales",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
          )
        ],
      ),
    );
  }

  PieChartSectionData _section(double value, String title, Color color, double total) {
    final double percentage = (value / total) * 100;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: 50,
      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem("Prot: ${goal!.targetProtein.toStringAsFixed(0)}g", Colors.blue),
        _legendItem("Carb: ${goal!.targetCarbs.toStringAsFixed(0)}g", Colors.orange),
        _legendItem("Gras: ${goal!.targetFat.toStringAsFixed(0)}g", Colors.red),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}