class RecipeValidation {
  final int? id;
  final int recipeId;
  final String reviewerId;
  final bool checkNutritionalAccuracy;
  final bool checkPhotoQuality;
  final bool checkInstructionClarity;
  final bool checkAllergenLabeling;
  final String reviewNotes;
  final DateTime? createdAt;

  RecipeValidation({
    this.id,
    required this.recipeId,
    required this.reviewerId,
    this.checkNutritionalAccuracy = false,
    this.checkPhotoQuality = false,
    this.checkInstructionClarity = false,
    this.checkAllergenLabeling = false,
    required this.reviewNotes, // Aseguramos que solo este se use
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'reviewer_id': reviewerId,
      'check_nutritional_accuracy': checkNutritionalAccuracy,
      'check_photo_quality': checkPhotoQuality,
      'check_instruction_clarity': checkInstructionClarity,
      'check_allergen_labeling': checkAllergenLabeling,
      'review_notes': reviewNotes,
    };
  }

  factory RecipeValidation.fromJson(Map<String, dynamic> json) {
    return RecipeValidation(
      id: json['id'],
      recipeId: json['recipe_id'],
      reviewerId: json['reviewer_id'],
      checkNutritionalAccuracy: json['check_nutritional_accuracy'] ?? false,
      checkPhotoQuality: json['check_photo_quality'] ?? false,
      checkInstructionClarity: json['check_instruction_clarity'] ?? false,
      checkAllergenLabeling: json['check_allergen_labeling'] ?? false,
      reviewNotes: json['review_notes'] ?? '', // Corregido el mapeo
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }
}