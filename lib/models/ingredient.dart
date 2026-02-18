class Ingredient {
  final int? pantryId;           
  final int ingredientMasterId;  // FK a Ingredient Master
  final String userId;
  final String name;             
  final String category;
  final double quantity;
  final String unit;
  final DateTime? expirationDate;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? status;

  Ingredient({
    this.pantryId,
    required this.ingredientMasterId,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.imageUrl,
    this.createdAt,
    this.status,
  });

  String? get id => pantryId?.toString();
  String get displayName => name;
  String get displayQuantity {
    if (quantity == quantity.truncateToDouble()) {
      return '${quantity.toInt()} $unit';
    }
    return '${quantity.toStringAsFixed(1)} $unit';
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final master = json['Ingredient'] as Map<String, dynamic>?;

    // CRÍTICO: El PK de Pantry también se llama 'ingredient_id'
    // Entonces pantryId E ingredientMasterId vienen del mismo campo
    final ingredientIdFromDB = json['ingredient_id'] as int?;
    
    return Ingredient(
      pantryId: ingredientIdFromDB,              // ← PK de Pantry
      ingredientMasterId: ingredientIdFromDB ?? 0,
      userId: json['user_id'] as String,
      name: master?['name'] as String? ?? json['name'] as String? ?? 'Desconocido',
      category: json['category'] as String? ?? 'Other',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'g',
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientMasterId,  // FK a Ingredient Master
      'user_id': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      if (expirationDate != null) 'expiration_date': expirationDate!.toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (status != null) 'status': status,
      
    };
  }

  Ingredient copyWith({
    int? pantryId,
    int? ingredientMasterId,
    String? userId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    String? imageUrl,
    DateTime? createdAt,
    String? status,
  }) {
    return Ingredient(
      pantryId: pantryId ?? this.pantryId,
      ingredientMasterId: ingredientMasterId ?? this.ingredientMasterId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

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
}