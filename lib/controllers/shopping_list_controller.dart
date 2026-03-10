import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingItem {
  final String id;
  final String name;
  double amount;
  String unit;
  bool isChecked;

  ShoppingItem({
    required this.id,
    required this.name,
    this.amount = 1.0,
    this.unit = '',
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
    'isChecked': isChecked,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'],
    name: json['name'],
    amount: (json['amount'] as num).toDouble(),
    unit: json['unit'] ?? '',
    isChecked: json['isChecked'] ?? false,
  );
}

class ShoppingListController extends GetxController {
  var items = <ShoppingItem>[].obs;
  static const String _storageKey = 'kooki_shopping_list';

  @override
  void onInit() {
    super.onInit();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString(_storageKey);
    if (itemsJson != null) {
      Iterable decoded = jsonDecode(itemsJson);
      items.value = decoded.map((e) => ShoppingItem.fromJson(e)).toList();
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addItem(String name, double amount, String unit) {
    // Check if item already exists un-checked
    final index = items.indexWhere(
      (i) => i.name.toLowerCase() == name.toLowerCase() && !i.isChecked,
    );
    if (index != -1) {
      items[index].amount += amount;
      items.refresh();
    } else {
      items.add(
        ShoppingItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          amount: amount,
          unit: unit,
        ),
      );
    }
    _saveItems();
  }

  void toggleItem(String id) {
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index].isChecked = !items[index].isChecked;
      items.refresh();
      _saveItems();
    }
  }

  void removeItem(String id) {
    items.removeWhere((i) => i.id == id);
    _saveItems();
  }

  void clearChecked() {
    items.removeWhere((i) => i.isChecked);
    _saveItems();
  }

  void addMissingIngredients(List<Map<String, dynamic>> missingItems) {
    for (var item in missingItems) {
      addItem(
        item['name'],
        item['amount'] is num ? (item['amount'] as num).toDouble() : 1.0,
        item['unit'] ?? '',
      );
    }
    Get.snackbar(
      'Añadidos a la lista',
      '${missingItems.length} ingredientes añadidos al carrito.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
