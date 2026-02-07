import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_master.dart';
import '../../data/repositories/ingredient_master_repository.dart';
import '../../controllers/pantry_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddIngredientScreen extends StatefulWidget {
  final Ingredient? ingredient;

  const AddIngredientScreen({super.key, this.ingredient});

  @override
  State<AddIngredientScreen> createState() => _AddIngredientScreenState();
}

class _AddIngredientScreenState extends State<AddIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _searchController = TextEditingController();
  final IngredientMasterRepository _masterRepo = IngredientMasterRepository();
  
  IngredientMaster? _selectedIngredient;
  List<IngredientMaster> _searchResults = [];
  String _selectedCategory = 'Dairy';
  String _selectedUnit = 'Grams (g)';
  DateTime? _expirationDate;
  File? _imageFile;
  bool _isLoading = false;
  bool _isSearching = false;

  final List<String> _categories = [
    'Produce',
    'Dairy',
    'Proteins',
    'Grains',
    'Other',
  ];

  final List<String> _units = [
    'Grams (g)',
    'Kilograms (kg)',
    'Liters (L)',
    'Milliliters (mL)',
    'Pieces',
    'Cups',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _quantityController.text = widget.ingredient!.numericQuantity.toString();
      _selectedCategory = widget.ingredient!.category;
      _selectedUnit = widget.ingredient!.unit;
      _expirationDate = widget.ingredient!.expirationDate;
    }
    _loadAllIngredients();
  }

  Future<void> _loadAllIngredients() async {
    try {
      final ingredients = await _masterRepo.fetchAllIngredients();
      setState(() => _searchResults = ingredients);
    } catch (e) {
      print('Error cargando ingredientes: $e');
    }
  }

  Future<void> _searchIngredients(String query) async {
    if (query.isEmpty) {
      _loadAllIngredients();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _masterRepo.searchIngredients(query);
      setState(() => _searchResults = results);
    } catch (e) {
      print('Error buscando: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIngredient == null) {
      Get.snackbar('Error', 'Selecciona un ingrediente');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<PantryController>();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🟡 PREPARANDO INGREDIENTE PARA GUARDAR');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (userId == null) {
        print('❌ Usuario no autenticado');
        Get.snackbar('Error', 'Usuario no autenticado');
        setState(() => _isLoading = false);
        return;
      }

      print('👤 User ID: $userId');
      print('🔢 Ingredient Master ID: ${_selectedIngredient!.ingredientId}');
      print('📝 Nombre: ${_selectedIngredient!.name}');

      // Construir quantity con formato: "100 g", "2.5 L", etc.
      final quantityValue = _quantityController.text.trim();
      final quantityFormatted = '$quantityValue $_selectedUnit';

      print('📊 Quantity formatted: $quantityFormatted');
      print('📦 Category: $_selectedCategory');
      print('⚖️ Unit: $_selectedUnit');

      final ingredient = Ingredient(
        pantryId: widget.ingredient?.pantryId,
        ingredientId: _selectedIngredient!.ingredientId,
        userId: userId,
        name: _selectedIngredient!.name,
        category: _selectedCategory,
        quantity: quantityFormatted,
        unit: _selectedUnit,
        expDate: _expirationDate,
        photoUrl: widget.ingredient?.photoUrl,
        boughtDate: widget.ingredient?.boughtDate ?? DateTime.now(),
      );

      print('🔵 Objeto Ingredient creado');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      bool success;
      if (widget.ingredient == null) {
        print('🆕 Modo: AGREGAR nuevo');
        success = await controller.addIngredient(ingredient);
      } else {
        print('✏️ Modo: ACTUALIZAR existente');
        success = await controller.updateIngredient(ingredient);
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print(success ? '✅ SUCCESS' : '❌ FAILED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (success && mounted) {
        Get.back();
      }
    } catch (e) {
      print('❌ Exception en _saveIngredient: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ingredient != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditing ? 'Edit Ingredient' : 'Add New Ingredient',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Picker (opcional - comentado por ahora)
            // GestureDetector(
            //   onTap: _pickImage,
            //   child: Container(...),
            // ),
            // const SizedBox(height: 24),

            // Ingredient Search
            const Text(
              'Ingredient Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _searchIngredients,
              decoration: InputDecoration(
                hintText: 'Search ingredient...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Search Results
            if (_searchResults.isNotEmpty && _searchController.text.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final ingredient = _searchResults[index];
                    return ListTile(
                      title: Text(ingredient.name),
                      selected: _selectedIngredient?.ingredientId ==
                          ingredient.ingredientId,
                      onTap: () {
                        setState(() {
                          _selectedIngredient = ingredient;
                          _searchController.text = ingredient.name;
                          _searchResults = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // Selected Ingredient Display
            if (_selectedIngredient != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: ${_selectedIngredient!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Quantity
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF4CAF50),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[300]!,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Expiration Date
            Row(
              children: [
                const Text(
                  'Expiration Date',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Optional',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectExpirationDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _expirationDate != null
                          ? '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: _expirationDate != null
                            ? Colors.black
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveIngredient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEditing
                                ? 'Update Ingredient'
                                : 'Add to Pantry',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}