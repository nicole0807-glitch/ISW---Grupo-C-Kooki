class UserGoalModel {
  final double currentWeight;
  final double height;
  final int age;
  final double activityLevel;
  final String goalType;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  UserGoalModel({
    required this.currentWeight,
    required this.height,
    required this.age,
    required this.activityLevel,
    required this.goalType,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  // Método para convertir a JSON (para enviar a Supabase/Backend)
  Map<String, dynamic> toJson() {
    return {
      'current_weight': currentWeight,
      'height': height,
      'age': age,
      'activity_level': activityLevel,
      'goal_type': goalType,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
    };
  }
  
  // Factory para crear desde JSON (si necesitas leer)
  factory UserGoalModel.fromJson(Map<String, dynamic> json) {
    return UserGoalModel(
      currentWeight: json['current_weight'],
      height: json['height'],
      age: json['age'],
      activityLevel: json['activity_level'],
      goalType: json['goal_type'],
      targetCalories: json['target_calories'],
      targetProtein: json['target_protein'],
      targetCarbs: json['target_carbs'],
      targetFat: json['target_fat'],
    );
  }
}