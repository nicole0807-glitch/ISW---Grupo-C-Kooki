import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_master.dart';
import '../../controllers/pantry_controller.dart';
import '../../providers/ingredient_master_provider.dart';
import 'widgets/ingredient_search_dropdown.dart';
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
  
  IngredientMaster? _selectedIngredient;  // ← CAMBIO PRINCIPAL
  String _selectedCategory = 'Dairy';
  String _selectedUnit = 'Grams (g)';
  DateTime? _expirationDate;
  File? _imageFile;
  bool _isLoading = false;

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
    
    // Inicializar el provider de ingredientes maestros
    Get.put(IngredientMasterProvider());
    
    if (widget.ingredient != null) {
      _quantityController.text = widget.ingredient!.quantity.toString();
      _selectedCategory = widget.ingredient!.category;
      _selectedUnit = widget.ingredient!.unit;
      _expirationDate = widget.ingredient!.expirationDate;
      _selectedIngredient = widget.ingredient!.ingredientMaster;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
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
    Get.snackbar(
      'Error',
      'Please select an ingredient from the list',
      backgroundColor: Colors.red[100],
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    print('🔵 ═══════════════════════════════════════');
    print('🔵 VERIFICANDO AUTENTICACIÓN');
    print('🔵 ═══════════════════════════════════════');
    
    final controller = Get.find<PantryController>();
    
    // ← AGREGAR ESTOS PRINTS
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentSession = Supabase.instance.client.auth.currentSession;
    
    print('👤 Current User: ${currentUser?.id}');
    print('📧 Email: ${currentUser?.email}');
    print('🎫 Session: ${currentSession != null ? "ACTIVA" : "INACTIVA"}');
    print('🔵 ═══════════════════════════════════════');
    
    final userId = currentUser?.id;

    if (userId == null) {
      print('❌ USER ID ES NULL - Usuario no autenticado');
      Get.snackbar('Error', 'Usuario no autenticado');
      setState(() => _isLoading = false);
      return;
    }
    
    print('✅ Usuario autenticado: $userId');

    final ingredient = Ingredient(
      pantryId: widget.ingredient?.pantryId,
      userId: userId,
      masterIngredientId: _selectedIngredient!.ingredientId,
      category: _selectedCategory,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _selectedUnit,
      expirationDate: _expirationDate,
      photoUrl: widget.ingredient?.photoUrl,
      createdAt: widget.ingredient?.createdAt,
      ingredientMaster: _selectedIngredient,
    );

    bool success;
    if (widget.ingredient == null) {
      success = await controller.addIngredient(ingredient);
    } else {
      success = await controller.updateIngredient(ingredient);
    }

    if (success && mounted) {
      Get.back();
    }
  } catch (e) {
    print('❌ Error en _saveIngredient: $e');
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
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF5F5F5),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : widget.ingredient?.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.ingredient!.photoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add a photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Optional, No fancy-looking',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),

            IngredientSearchDropdown(
              initialIngredient: _selectedIngredient,
              onIngredientSelected: (selected) {
                setState(() {
                  _selectedIngredient = selected;
                });
              },
            ),
            const SizedBox(height: 20),

            // Quantity and Unit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedUnit = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pantry Category
            const Text(
              'Pantry Category',
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
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

            // Add to Pantry Button
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
                            isEditing ? 'Update Ingredient' : 'Add to Pantry',
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