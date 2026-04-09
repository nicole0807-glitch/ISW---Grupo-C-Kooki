import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/goal_controller.dart';
import '../../models/user_goal_model.dart';
import '../recipe/widgets/macro_chart_widget.dart';

class GoalRegistrationScreen extends StatelessWidget {
  const GoalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoalController()..loadExistingGoals(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Registro de Metas")),
        body: Consumer<GoalController>(
          builder: (context, controller, child) {
            // Mostrar spinner mientras carga los datos iniciales
            if (controller.isLoading && controller.ageCtrl.text.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Datos Físicos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Inputs de Edad, Altura, Peso
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            controller.ageCtrl,
                            "Edad",
                            "años",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            controller.heightCtrl,
                            "Altura",
                            "cm",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            controller.weightCtrl,
                            "Peso",
                            "kg",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dropdowns
                    _buildDropdown(
                      "Nivel de Actividad",
                      controller.activityLevel,
                      (val) {
                        controller.activityLevel = val!;
                        controller.previewCalculation();
                      },
                      [
                        const DropdownMenuItem(
                          value: 1.2,
                          child: Text("Sedentario"),
                        ),
                        const DropdownMenuItem(
                          value: 1.375,
                          child: Text("Ligero (1-3 días)"),
                        ),
                        const DropdownMenuItem(
                          value: 1.55,
                          child: Text("Moderado (3-5 días)"),
                        ),
                        const DropdownMenuItem(
                          value: 1.725,
                          child: Text("Intenso (6-7 días)"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _buildDropdown(
                      "Meta",
                      controller.goalType,
                      (val) {
                        controller.goalType = val!;
                        controller.previewCalculation();
                      },
                      [
                        const DropdownMenuItem(
                          value: 'lose',
                          child: Text("Bajar de Peso"),
                        ),
                        const DropdownMenuItem(
                          value: 'maintain',
                          child: Text("Mantener Peso"),
                        ),
                        const DropdownMenuItem(
                          value: 'gain',
                          child: Text("Subir de Peso"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Botón Calcular (Opcional si se hace reactivo)
                    ElevatedButton(
                      onPressed: controller.previewCalculation,
                      child: const Text("Calcular Plan Nutricional"),
                    ),

                    const Divider(height: 40),

                    // Resultado y Gráfico
                    if (controller.currentGoal != null) ...[
                      const Divider(height: 40),
                      MacroChartWidget(
                        goal: controller.currentGoal,
                      ), // Reutilización mágica
                    ],

                    const SizedBox(height: 30),

                    const SizedBox(
                      height: 40,
                    ), // Espacio extra antes del botón final

                    Center(
                      child: SizedBox(
                        width: double
                            .infinity, // Ocupa el ancho disponible (respetando el padding del Form)
                        height: 55, // Altura más cómoda para presionar
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF13EC5B,
                            ), // Tu verde vibrante
                            foregroundColor:
                                Colors.black, // Color del texto/icono
                            elevation: 4, // Sombra para dar profundidad
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), // Bordes redondeados modernos
                            ),
                          ),
                          onPressed: controller.isLoading
                              ? null
                              : () async {
                                  final success = await controller.saveGoals();
                                  if (!context.mounted) return;

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "¡Metas actualizadas con éxito!",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Error al guardar. Intenta de nuevo.",
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          child: controller.isLoading
                              ? const SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "GUARDAR PLAN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing:
                                        1.2, // Espaciado de letras para un look premium
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Margen inferior final
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, String suffix) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        if (double.tryParse(value) == null) return 'Inválido';
        return null;
      },
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    Function(T?) onChanged,
    List<DropdownMenuItem<T>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          items: items,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generateChartSections(UserGoalModel goal) {
    final total = goal.targetCalories;
    final pCals = goal.targetProtein * 4;
    final cCals = goal.targetCarbs * 4;
    final fCals = goal.targetFat * 9;

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: pCals,
        title: '${(pCals / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: cCals,
        title: '${(cCals / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: fCals,
        title: '${(fCals / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  Widget _buildLegend(UserGoalModel goal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(
          "Proteínas",
          Colors.blue,
          "${goal.targetProtein.toStringAsFixed(0)}g",
        ),
        _legendItem(
          "Carbos",
          Colors.orange,
          "${goal.targetCarbs.toStringAsFixed(0)}g",
        ),
        _legendItem(
          "Grasas",
          Colors.red,
          "${goal.targetFat.toStringAsFixed(0)}g",
        ),
      ],
    );
  }

  Widget _legendItem(String text, Color color, String value) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 5),
            const SizedBox(width: 5),
            Text(text),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
