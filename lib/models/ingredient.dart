class Ingredient {
  final int? pantryId;          
  final int ingredientId;        // ingredient_id (FK a Ingredient master)
  final String userId;           // user_id (FK a Profile)
  final String name;             // Viene del JOIN con Ingredient
  final String category;
  final String quantity;         // measure_type (puede ser "100 g", "2 L", etc)
  final String unit;
  final DateTime? expDate;
  final String? photoUrl;
  final DateTime? boughtDate;

  Ingredient({
    this.pantryId,
    required this.ingredientId,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expDate,
    this.photoUrl,
    this.boughtDate,
  });

  // Getters para compatibilidad con código existente
  String? get id => pantryId?.toString();
  DateTime? get expirationDate => expDate;
  String? get imageUrl => photoUrl;
  // Nombre para mostrar (compatibilidad con UI que espera `displayName`)
  String get displayName => name;
  DateTime? get createdAt => boughtDate;
  String get status => 'Fresh';

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    // El JOIN trae: Pantry.*, Ingredient(name)
    final ingredientMaster = json['Ingredient'];
    
    return Ingredient(
      pantryId: json['pantry_id'] as int?,
      ingredientId: json['ingredient_id'] as int,
      userId: json['user_id'] as String,
      name: ingredientMaster != null 
          ? (ingredientMaster['name'] as String)
          : 'Desconocido',
      category: json['category'] as String? ?? 'Other',
      quantity: json['quantity']?.toString() ?? '0',
      unit: json['unit'] as String? ?? 'g',
      expDate: json['exp_date'] != null
          ? DateTime.parse(json['exp_date'] as String)
          : null,
      photoUrl: json['photo_url'] as String?,
      boughtDate: json['bought_date'] != null
          ? DateTime.parse(json['bought_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (pantryId != null) 'pantry_id': pantryId,
      'ingredient_id': ingredientId,
      'user_id': userId,
      'category': category,
      'quantity': quantity,  // Enviar como string: "100 g"
      'unit': unit,
      if (expDate != null) 'exp_date': expDate!.toIso8601String(),
      if (photoUrl != null) 'photo_url': photoUrl,
      if (boughtDate != null) 'bought_date': boughtDate!.toIso8601String(),
    };
  }

  Ingredient copyWith({
    int? pantryId,
    int? ingredientId,
    String? userId,
    String? name,
    String? category,
    String? quantity,
    String? unit,
    DateTime? expDate,
    String? photoUrl,
    DateTime? boughtDate,
  }) {
    return Ingredient(
      pantryId: pantryId ?? this.pantryId,
      ingredientId: ingredientId ?? this.ingredientId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expDate: expDate ?? this.expDate,
      photoUrl: photoUrl ?? this.photoUrl,
      boughtDate: boughtDate ?? this.boughtDate,
    );
  }

  bool get isExpired {
    if (expDate == null) return false;
    return expDate!.isBefore(DateTime.now());
  }

  bool get expiresSoon {
    if (expDate == null) return false;
    final daysUntilExpiration = expDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 3 && daysUntilExpiration >= 0;
  }

  int? get daysUntilExpiration {
    if (expDate == null) return null;
    return expDate!.difference(DateTime.now()).inDays;
  }

  // Parsear quantity numérica (por si quantity = "100 g")
  double get numericQuantity {
    final match = RegExp(r'[\d.]+').firstMatch(quantity);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0;
    }
    return double.tryParse(quantity) ?? 0;
  }
}