import 'package:flutter/material.dart';
import '../../controllers/onboarding_controller.dart';
import '../../utils/app_colors.dart';
import 'diet_selection_screen.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});
  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final OnboardingController _controller = OnboardingController();
  String? _selectedGoal;
  
  final List<Map<String, dynamic>> _goals = [
    {'title': 'Comer más sano', 'desc': 'Enfócate en alimentos nutritivos y completos.', 'icon': Icons.favorite_rounded},
    {'title': 'Perder peso', 'desc': 'Controla calorías y macronutrientes.', 'icon': Icons.monitor_weight_rounded},
    {'title': 'Ahorrar dinero', 'desc': 'Reduce desperdicios y gastos fuera de casa.', 'icon': Icons.savings_rounded},
    {'title': 'Aprender a cocinar', 'desc': 'Domina nuevas recetas y técnicas.', 'icon': Icons.restaurant_menu_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text("1 de 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 0.33, color: AppColors.nutveDarkGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("¿Cuál es tu objetivo principal?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isSelected = _selectedGoal == goal['title'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGoal = goal['title']),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.nutveSelectionGreen : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? AppColors.nutveSelectionGreen : Colors.black12),
                            ),
                            child: Row(
                              children: [
                                Icon(goal['icon'], color: isSelected ? Colors.white : Colors.black87),
                                const SizedBox(width: 15),
                                Expanded(child: Text(goal['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black))),
                                Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.black26),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveDarkGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _selectedGoal == null
                  ? null
                  : () {
                      _controller.setGoal(_selectedGoal!);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DietSelectionScreen()));
                    },
              child: const Text("CONTINUAR"),
            ),
          ],
        ),
      ),
    );
  }
}