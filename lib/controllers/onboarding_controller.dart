import '../services/supabase_service.dart';

class OnboardingController {
  final SupabaseService _service = SupabaseService();

  static String? goal;
  static List<String> diets = [];
  static List<String> allergies = [];

  void setGoal(String value) => goal = value;
  
  void toggleDiet(String diet, bool isSelected) {
    if (diet == "None") {
      diets.clear();
      diets.add("None");
    } else {
      diets.remove("None");
      isSelected ? diets.add(diet) : diets.remove(diet);
    }
  }

  void toggleAllergy(String allergy, bool isSelected) {
    if (allergy == "None") {
      allergies.clear();
      allergies.add("None");
    } else {
      allergies.remove("None");
      isSelected ? allergies.add(allergy) : allergies.remove(allergy);
    }
  }

  bool validateDietSelection() {
    return diets.isNotEmpty && allergies.isNotEmpty;
  }

  Future<void> saveUserPreferences(String cookingTime, String cookingSkill) async {
    try {
      final user = _service.currentUser;
      if (user != null) {
        List<String> tagsToSave = [];
        
        if (goal != null) tagsToSave.add(goal!);
        tagsToSave.addAll(diets);
        tagsToSave.add(cookingTime);
        tagsToSave.add(cookingSkill);

        await _service.saveUserPreferences(user.id, tagsToSave);

        await _service.saveUserAllergies(user.id, allergies);
      }
    } catch (e) {
      rethrow;
    }
  }
}