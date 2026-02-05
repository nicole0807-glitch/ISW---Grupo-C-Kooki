import 'package:flutter/material.dart';
import '../../controllers/onboarding_controller.dart';
import '../../utils/app_colors.dart';
import 'cooking_skill_screen.dart';

class DietSelectionScreen extends StatefulWidget {
  const DietSelectionScreen({super.key});
  @override
  State<DietSelectionScreen> createState() => _DietSelectionScreenState();
}

class _DietSelectionScreenState extends State<DietSelectionScreen> {
  final OnboardingController _controller = OnboardingController();
  
  final List<String> _diets = [
    "Vegan",
    "Keto",
    "Vegetarian",
    "Paleo",
    "Low Carb",
    "Mediterranean",
  ];
  final List<String> _allergies = [
    "Dairy",
    "Gluten",
    "Soy",
    "Shellfish",
    "Nuts",
    "None",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("2 of 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 0.66, color: AppColors.nutveDarkGreen),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What is your diet?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Dietary patterns:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Pasamos la lista estática del controlador para ver los cambios reflejados
                    _buildSelectionGrid(_diets, OnboardingController.diets, true),
                    const SizedBox(height: 30),
                    const Text(
                      "Allergies:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSelectionGrid(
                      _allergies,
                      OnboardingController.allergies,
                      false,
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveDarkGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              // Validamos que haya algo seleccionado usando el método del controller
              onPressed: !_controller.validateDietSelection()
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CookingSkillScreen(),
                        ),
                      );
                    },
              child: const Text("CONTINUAR"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGrid(List<String> options, List<String> selectedList, bool isDiet) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (val) => setState(() {
            // --- CORRECCIÓN AQUÍ ---
            // Antes usabas 'isSelected' (estado viejo), ahora usamos 'val' (nuevo estado true/false)
            if (isDiet) {
              _controller.toggleDiet(option, val);
            } else {
              _controller.toggleAllergy(option, val);
            }
          }),
          selectedColor: AppColors.nutveSelectionGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }
}