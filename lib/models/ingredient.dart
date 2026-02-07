import 'ingredient_master.dart';

/// Modelo para la tabla Pantry (despensa del usuario)
class Ingredient {
  final int? pantryId;  // PK de Pantry
  final String userId;
  final int masterIngredientId;  // FK a tabla Ingredient
  final String? name;  // Deprecado, ahora viene de la relación
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expirationDate;
  final String? photoUrl;
  final DateTime? createdAt;
  
  // Relación con ingrediente maestro (se llena con JOIN)
  final IngredientMaster? ingredientMaster;

  Ingredient({
    this.pantryId,
    required this.userId,
    required this.masterIngredientId,
    this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.photoUrl,
    this.createdAt,
    this.ingredientMaster,
  });

  // Getters de compatibilidad
  int? get id => pantryId;
  String? get ingredientId => pantryId?.toString();
  String? get imageUrl => photoUrl;
  
  // Nombre del ingrediente (prioriza el de la relación)
  String get displayName => ingredientMaster?.name ?? name ?? 'Unknown';

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      pantryId: json['ingredient_id'] as int?,
      userId: json['user_id'] as String,
      masterIngredientId: json['master_ingredient_id'] as int? ?? 0,
      name: json['name'] as String?,
      category: json['category'] as String? ?? 'Other',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'unit',
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      photoUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      // Si hay datos de JOIN, crear el objeto relacionado
      ingredientMaster: json['Ingredient'] != null
          ? IngredientMaster.fromJson(json['Ingredient'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pantryId != null) 'ingredient_id': pantryId,
      'user_id': userId,
      'master_ingredient_id': masterIngredientId,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      if (expirationDate != null) 
        'expirationDate': expirationDate!.toIso8601String(),
      if (photoUrl != null) 'imageUrl': photoUrl,
      // No enviamos 'name' porque viene de la tabla maestra
    };
  }

  Ingredient copyWith({
    int? pantryId,
    String? userId,
    int? masterIngredientId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    String? photoUrl,
    DateTime? createdAt,
    IngredientMaster? ingredientMaster,
  }) {
    return Ingredient(
      pantryId: pantryId ?? this.pantryId,
      userId: userId ?? this.userId,
      masterIngredientId: masterIngredientId ?? this.masterIngredientId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      ingredientMaster: ingredientMaster ?? this.ingredientMaster,
    );
  }

  // Métodos de utilidad
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  bool get expiresSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 3 && daysUntilExpiration >= 0;
  }

  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    return expirationDate!.difference(DateTime.now()).inDays;
  }

  String get status {
    if (isExpired) return 'Expired';
    if (expiresSoon) return 'Expiring Soon';
    if (quantity < 100) return 'Low Stock';
    return 'Fresh';
  }
}