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
  List<IngredientMaster> _allIngredients = [];   // Lista completa siempre cargada
  List<IngredientMaster> _searchResults = [];    // Lista filtrada por búsqueda
  bool _showDropdown = false;                    // Controla visibilidad del dropdown
  String _selectedCategory = 'Produce';
  String _selectedUnit = 'g';
  DateTime? _expirationDate;
  bool _isLoading = false;
  bool _isSearching = false;

  final List<String> _categories = [
    'Produce',
    'Dairy',
    'Protein',
    'Grains',
    'Other',
  ];

  final List<String> _units = ['g', 'kg', 'mL', 'L', 'Pieces', 'Cups'];

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _quantityController.text = widget.ingredient!.quantity.toString();
      _selectedCategory = widget.ingredient!.category;
      _selectedUnit = widget.ingredient!.unit;
      _expirationDate = widget.ingredient!.expirationDate;
    }
    _loadAllIngredients();
  }

  // Carga TODOS los ingredientes al iniciar
  Future<void> _loadAllIngredients() async {
    try {
      final ingredients = await _masterRepo.fetchAllIngredients();
      setState(() {
        _allIngredients = ingredients;
        _searchResults = ingredients; // Inicialmente muestra todos
      });
    } catch (e) {
      print('Error cargando ingredientes: $e');
    }
  }

  // Filtra según texto ingresado
  void _onSearchChanged(String query) {
    setState(() {
      _showDropdown = true;
      if (query.isEmpty) {
        _searchResults = _allIngredients; // Muestra todos si no hay texto
      } else {
        _searchResults = _allIngredients
            .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Al enfocar el campo, mostrar dropdown con todos los ingredientes
  void _onSearchFocus() {
    setState(() {
      _showDropdown = true;
      if (_searchController.text.isEmpty) {
        _searchResults = _allIngredients;
      }
    });
  }

  void _selectIngredient(IngredientMaster ingredient) {
    setState(() {
      _selectedIngredient = ingredient;
      _searchController.text = ingredient.name;
      _showDropdown = false;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIngredient == null) {
      Get.snackbar('Error', 'Selecciona un ingrediente de la lista');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<PantryController>();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        Get.snackbar('Error', 'Usuario no autenticado');
        setState(() => _isLoading = false);
        return;
      }

      final quantityValue = double.parse(_quantityController.text.trim());

      final ingredient = Ingredient(
        pantryId: widget.ingredient?.pantryId,
        ingredientMasterId: _selectedIngredient!.ingredientId,
        userId: userId,
        name: _selectedIngredient!.name,
        category: _selectedCategory,
        quantity: quantityValue,
        unit: _selectedUnit,
        expirationDate: _expirationDate,
        imageUrl: null,
        createdAt: DateTime.now(),
        status: 'Fresh',
      );

      bool success;
      if (widget.ingredient == null) {
        success = await controller.addIngredient(ingredient);
      } else {
        success = await controller.updateIngredient(ingredient);
      }

      if (success && mounted) Get.back();
    } catch (e) {
      print('❌ Error: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ingredient != null;

    return GestureDetector(
      // Cerrar dropdown al tocar fuera
      onTap: () => setState(() => _showDropdown = false),
      child: Scaffold(
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Ingredient Search ──────────────────────────────────────
              const Text(
                'Ingredient Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Campo de búsqueda con dropdown integrado
              Column(
                children: [
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (hasFocus) _onSearchFocus();
                    },
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onTap: _onSearchFocus,
                      decoration: InputDecoration(
                        hintText: 'Buscar o seleccionar ingrediente...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _selectedIngredient = null;
                                    _searchResults = _allIngredients;
                                    _showDropdown = true;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Dropdown lista de ingredientes
                  if (_showDropdown && _searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final isSelected =
                              _selectedIngredient?.ingredientId == item.ingredientId;
                          return ListTile(
                            dense: true,
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check,
                                    color: Color(0xFF4CAF50), size: 18)
                                : null,
                            onTap: () => _selectIngredient(item),
                          );
                        },
                      ),
                    ),

                  // Mensaje si no hay resultados
                  if (_showDropdown && _searchResults.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No se encontraron ingredientes',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Ingrediente seleccionado
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
                      Expanded(
                        child: Text(
                          'Seleccionado: ${_selectedIngredient!.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // ── Quantity ───────────────────────────────────────────────
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
                          return 'Número inválido';
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
                      items: _units
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Category ───────────────────────────────────────────────
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
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
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

              // ── Expiration Date ────────────────────────────────────────
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
                      horizontal: 16, vertical: 14),
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
                      const Spacer(),
                      if (_expirationDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: Colors.grey),
                          onPressed: () =>
                              setState(() => _expirationDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save Button ────────────────────────────────────────────
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
                              color: Colors.white, strokeWidth: 2),
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
      ),
    );
  }
}