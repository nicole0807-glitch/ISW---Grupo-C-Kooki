// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  List<IngredientMaster> _allIngredients = []; // Lista completa siempre cargada
  List<IngredientMaster> _searchResults = []; // Lista filtrada por búsqueda
  bool _showDropdown = false; // Controla visibilidad del dropdown
  String _selectedCategory = 'Produce';
  String _selectedUnit = 'g';
  DateTime? _expirationDate;
  // ignore: unused_field
  File? _imageFile;
  bool _isLoading = false;
  final bool _isSearching = false;

  final List<String> _categories = [
    'Frutas y verduras',
    'Lácteos',
    'Proteínas',
    'Cereales',
    'Otros',
  ];

  final List<String> _units = ['g', 'kg', 'mL', 'L', 'Piezas', 'Tazas'];

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
        // ← CAMBIO: Respetar modo oscuro
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF4CAF50),
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF4CAF50),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _saveIngredient() async {
    final isEditing = widget.ingredient != null;
    if (!_formKey.currentState!.validate()) return;

    // En modo crear, validamos que haya seleccionado un ingrediente de la lista maestra
    if (!isEditing && _selectedIngredient == null) {
      Get.snackbar('Error', 'Selecciona un ingrediente de la lista');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<PantryController>();
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        Get.snackbar('Error', 'Usuario no autenticado');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final quantityValue = double.parse(_quantityController.text.trim());

      final ingredientToSave = Ingredient(
        pantryId: widget.ingredient?.pantryId,
        ingredientMasterId: isEditing
            ? widget.ingredient!.ingredientMasterId
            : _selectedIngredient!.ingredientId,
        userId: userId,
        name: isEditing ? widget.ingredient!.name : _selectedIngredient!.name,
        category: _selectedCategory,
        quantity: quantityValue,
        unit: _selectedUnit,
        expirationDate: _expirationDate,
        imageUrl: null,
        createdAt: widget.ingredient?.createdAt ?? DateTime.now(),
        status: widget.ingredient?.status ?? 'Fresco',
      );

      bool success;
      if (!isEditing) {
        print('🆕 Agregando nuevo ingrediente...');
        success = await controller.addIngredient(ingredientToSave);
        print('🔵 addIngredient retornó: $success');
      } else {
        print('✏️ Actualizando ingrediente...');
        success = await controller.updateIngredient(ingredientToSave);
        print('🔵 updateIngredient retornó: $success');
      }

      print('🔍 success: $success, mounted: $mounted');

      if (success && mounted) {
        print('✅ Cerrando pantalla...');
        // Esperar para que se vea el snackbar antes de cerrar
        await Future.delayed(const Duration(milliseconds: 900));

        // Intentar con Navigator en lugar de GetX
        Navigator.of(context).pop();

        print('✅ Pantalla cerrada');
      } else {
        print('❌ NO se cierra - success: $success, mounted: $mounted');
      }
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
    
    // ← AGREGAR: Obtener colores del tema
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _showDropdown = false),
      child: Scaffold(
        backgroundColor: bgColor,  // ← CAMBIO
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,  // ← CAMBIO
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: textColor),  // ← CAMBIO
            onPressed: () => Get.back(),
          ),
          title: Text(
            isEditing ? 'Editar ingrediente' : 'Agregar nuevo ingrediente',
            style: TextStyle(
              color: textColor,  // ← CAMBIO
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancelar',
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
              // ── Ingredient Search ──────────────────────────────────────
              Text(
                'Nombre del ingrediente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,  // ← CAMBIO
                ),
              ),
              const SizedBox(height: 8),

              // Campo de búsqueda con dropdown integrado o Vista de sólo lectura
              if (isEditing)
                // Modo Editar: Vista de sólo lectura con candado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05)  // ← CAMBIO: fondo sutil
                        : const Color(0xFFF3F4F6),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock, 
                        size: 20, 
                        color: isDark ? Colors.white : Colors.grey,  // ← CAMBIO: candado blanco
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.ingredient!.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark 
                                ? Colors.grey[400]  // ← CAMBIO: texto gris oscuro
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
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
                          color: cardColor,  // ← CAMBIO
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey[300]!,
                          ),
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
                                _selectedIngredient?.ingredientId ==
                                item.ingredientId;
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
                                      : textColor,  // ← CAMBIO: texto blanco en modo oscuro
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF4CAF50),
                                      size: 18,
                                    )
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
              if (!isEditing) const SizedBox(height: 12),

              // Ingrediente seleccionado (solo en modo crear)
              if (!isEditing && _selectedIngredient != null)
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
              Text(
                'Cantidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,  // ← CAMBIO
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
                          return 'Obligatorio';
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
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _units
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUnit = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Category ───────────────────────────────────────────────
              Text(
                'Categoría',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,  // ← CAMBIO
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
                    backgroundColor: cardColor,  // ← CAMBIO
                    selectedColor: const Color(0xFF4CAF50),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,  // ← CAMBIO
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : isDark 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[300]!,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Expiration Date ────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Fecha de caducidad',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,  // ← CAMBIO
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Opcional',
                    style: TextStyle(
                      fontSize: 12, 
                      color: textColor.withOpacity(0.6),  // ← CAMBIO
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
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: textColor.withOpacity(0.7),  // ← CAMBIO
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _expirationDate != null
                            ? '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}'
                            : 'Selecciona fecha',
                        style: TextStyle(
                          color: _expirationDate != null
                              ? textColor  // ← CAMBIO
                              : textColor.withOpacity(0.5),  // ← CAMBIO
                        ),
                      ),
                      const Spacer(),
                      if (_expirationDate != null)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: Colors.grey,
                          ),
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
                                  ? 'Actualizar ingrediente'
                                  : 'Agregar a la despensa',
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
