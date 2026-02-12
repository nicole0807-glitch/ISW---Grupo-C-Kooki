import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_goal_model.dart';

class GoalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CÁLCULO DE MACROS REALISTAS (HU-27)
  UserGoalModel calculatePlan({
    required double weight,
    required double height,
    required int age,
    required double activityLevel,
    required String goalType,
    required String gender,
  }) {
    double bmr = (gender == 'female')
        ? (10 * weight) + (6.25 * height) - (5 * age) - 161
        : (10 * weight) + (6.25 * height) - (5 * age) + 5;

    double tdee = bmr * activityLevel;
    double targetCalories = tdee;

    if (goalType == 'lose') targetCalories -= 400;
    if (goalType == 'gain') targetCalories += 300;

    double proteinGrams = weight * 1.8;
    double fatCalories = targetCalories * 0.25;
    double fatGrams = fatCalories / 9;
    double carbCalories = targetCalories - ((proteinGrams * 4) + fatCalories);
    double carbGrams = carbCalories / 4;

    return UserGoalModel(
      currentWeight: weight,
      height: height,
      age: age,
      activityLevel: activityLevel,
      goalType: goalType,
      targetCalories: targetCalories,
      targetProtein: proteinGrams,
      targetCarbs: carbGrams,
      targetFat: fatGrams,
    );
  }

  // --- NUEVO: MÉTODO PARA LEER DE LA DB ---
  Future<UserGoalModel?> getUserGoals(String userId) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserGoalModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserGoals(UserGoalModel goal, String userId) async {
    try {
      await _supabase.from('user_goals').upsert({
        'user_id': userId,
        ...goal.toJson(),
      });
    } catch (e) {
      throw Exception('Error guardando metas: $e');
    }
  }
}