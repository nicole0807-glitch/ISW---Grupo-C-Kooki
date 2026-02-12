import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/ingredient_master.dart';
import '../../../providers/ingredient_master_provider.dart';

class IngredientSearchDropdown extends StatefulWidget {
  final Function(IngredientMaster?) onIngredientSelected;
  final IngredientMaster? initialIngredient;

  const IngredientSearchDropdown({
    super.key,
    required this.onIngredientSelected,
    this.initialIngredient,
  });

  @override
  State<IngredientSearchDropdown> createState() =>
      _IngredientSearchDropdownState();
}

class _IngredientSearchDropdownState extends State<IngredientSearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  IngredientMaster? _selectedIngredient;

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      _selectedIngredient = widget.initialIngredient;
      _searchController.text = widget.initialIngredient!.name;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Get.find<IngredientMasterProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nombre del Ingrediente',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        Obx(() {
          if (provider.isLoading.value) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Cargando ingredientes...'),
                ],
              ),
            );
          }

          if (provider.errorMessage.isNotEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.red[50],
              ),
              child: Text(
                'Error: ${provider.errorMessage.value}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return Autocomplete<IngredientMaster>(
            initialValue: _selectedIngredient != null
                ? TextEditingValue(text: _selectedIngredient!.name)
                : null,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return provider.allIngredients.take(10);
              }
              return provider.allIngredients.where((ingredient) {
                return ingredient.name
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              }).take(10);
            },
            displayStringForOption: (IngredientMaster option) => option.name,
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              _searchController.text = controller.text;
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Busca ingredientes (e.g., aguacate, tomate)...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _selectedIngredient != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            controller.clear();
                            setState(() {
                              _selectedIngredient = null;
                            });
                            widget.onIngredientSelected(null);
                          },
                        )
                      : null,
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
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (_selectedIngredient == null) {
                    return 'Porfavor, seleccione un ingrediente válido.';
                  }
                  return null;
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: MediaQuery.of(context).size.width - 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final ingredient = options.elementAt(index);
                        return ListTile(
                          leading: const Icon(Icons.fastfood, color: Color(0xFF4CAF50)),
                          title: Text(
                            ingredient.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {
                            onSelected(ingredient);
                            setState(() {
                              _selectedIngredient = ingredient;
                            });
                            widget.onIngredientSelected(ingredient);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (IngredientMaster selection) {
              setState(() {
                _selectedIngredient = selection;
              });
              widget.onIngredientSelected(selection);
            },
          );
        }),
        
        if (_selectedIngredient != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_selectedIngredient!.name}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}