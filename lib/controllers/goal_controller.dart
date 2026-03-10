import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_goal_model.dart';
import '../services/goal_service.dart';

class GoalController extends ChangeNotifier {
  final GoalService _service = GoalService();
  
  final formKey = GlobalKey<FormState>();
  // Controladores para los campos de texto
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  // Variables de estado
  double activityLevel = 1.2;
  String goalType = 'maintain';
  UserGoalModel? currentGoal;
  bool isLoading = false;

  // --- EL MÉTODO QUE FALTABA ---
  Future<void> loadExistingGoals() async {
    isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Llamamos al servicio para buscar en la base de datos
      final savedGoal = await _service.getUserGoals(userId);

      if (savedGoal != null) {
        currentGoal = savedGoal;
        
        // Rellenamos los campos de texto con lo que hay en la DB
        ageCtrl.text = savedGoal.age.toString();
        heightCtrl.text = savedGoal.height.toString();
        weightCtrl.text = savedGoal.currentWeight.toString();
        activityLevel = savedGoal.activityLevel;
        goalType = savedGoal.goalType;
      }
    } catch (e) {
      debugPrint("Error cargando metas en el controlador: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Lógica para previsualizar antes de guardar
  void previewCalculation() {
    if (ageCtrl.text.isEmpty || heightCtrl.text.isEmpty || weightCtrl.text.isEmpty) return;

    currentGoal = _service.calculatePlan(
      weight: double.parse(weightCtrl.text),
      height: double.parse(heightCtrl.text),
      age: int.parse(ageCtrl.text),
      activityLevel: activityLevel,
      goalType: goalType,
      gender: 'male', // Podrías hacerlo dinámico después
    );
    notifyListeners();
  }

  // Guardar en Supabase
  Future<bool> saveGoals() async {
    if (currentGoal == null) previewCalculation();
    if (currentGoal == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      await _service.saveUserGoals(currentGoal!, userId);
      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }
}