import 'package:flutter/material.dart';
import '../../controllers/onboarding_controller.dart';
import '../../utils/app_colors.dart';
import 'success_screen.dart';

class CookingSkillScreen extends StatefulWidget {
  const CookingSkillScreen({super.key});
  @override
  State<CookingSkillScreen> createState() => _CookingSkillScreenState();
}

class _CookingSkillScreenState extends State<CookingSkillScreen> {
  final OnboardingController _controller = OnboardingController();
  String? _selectedTime;
  String? _selectedSkill;
  bool _isFinalizing = false;

  final List<Map<String, dynamic>> _skills = [
    {'title': 'Beginner', 'desc': 'I am just starting to cook.', 'icon': Icons.egg_outlined},
    {'title': 'Intermediate', 'desc': 'I know the basics.', 'icon': Icons.soup_kitchen_outlined},
    {'title': 'Pro', 'desc': 'I am a kitchen master.', 'icon': Icons.outdoor_grill_outlined},
  ];

  Future<void> _saveAndFinish() async {
    setState(() => _isFinalizing = true);
    try {
      await _controller.saveUserPreferences(_selectedTime!, _selectedSkill!);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("3 of 3", style: TextStyle(fontSize: 14)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(6),
          child: LinearProgressIndicator(value: 1.0, color: AppColors.nutveDarkGreen),
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
                    const Text("How much time do you have to cook?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['15 min', '30 min', '+60 min'].map((time) {
                        final isSelected = _selectedTime == time;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = time),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.26,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.nutveSelectionGreen : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? AppColors.nutveSelectionGreen : Colors.black12),
                            ),
                            child: Center(child: Text(time, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    const Text("Cooking Skill", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text("Menciona tu nivel de habilidad de cocina", style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 20),
                    ..._skills.map((skill) {
                      final isSelected = _selectedSkill == skill['title'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSkill = skill['title']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.nutveSelectionGreen : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? AppColors.nutveSelectionGreen : Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Icon(skill['icon'], size: 30, color: isSelected ? Colors.white : AppColors.nutveDarkGreen),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(skill['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                                  Text(skill['desc'], style: TextStyle(color: isSelected ? Colors.white70 : Colors.black54)),
                                ],
                              ),
                              const Spacer(),
                              Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : Colors.black26),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            _isFinalizing
                ? const CircularProgressIndicator(color: AppColors.nutveDarkGreen)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.nutveDarkGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: (_selectedTime == null || _selectedSkill == null) ? null : _saveAndFinish,
                    child: const Text("FINALIZAR"),
                  ),
          ],
        ),
      ),
    );
  }
}