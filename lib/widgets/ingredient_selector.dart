import 'package:flutter/material.dart';
import '../models/ingredient_master.dart';
import '../data/repositories/ingredient_master_repository.dart';
import '../utils/app_colors.dart';

class IngredientSelector extends StatefulWidget {
  final Function(IngredientMaster) onSelected;
  final String? initialValue;
  final bool isDark;

  const IngredientSelector({
    super.key,
    required this.onSelected,
    this.initialValue,
    required this.isDark,
  });

  @override
  State<IngredientSelector> createState() => _IngredientSelectorState();
}

class _IngredientSelectorState extends State<IngredientSelector> {
  final TextEditingController _searchController = TextEditingController();
  final IngredientMasterRepository _masterRepo = IngredientMasterRepository();
  final FocusNode _focusNode = FocusNode();

  List<IngredientMaster> _allIngredients = [];
  List<IngredientMaster> _searchResults = [];
  bool _showDropdown = false;
  bool _isLoading = true;
  IngredientMaster? _selectedIngredient;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialValue ?? '';
    _loadAllIngredients();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay to allow clicking on a list item
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showDropdown = false);
        });
      }
    });
  }

  Future<void> _loadAllIngredients() async {
    try {
      final ingredients = await _masterRepo.fetchAllIngredients();
      if (mounted) {
        setState(() {
          _allIngredients = ingredients;
          _searchResults = ingredients;
          _isLoading = false;

          if (widget.initialValue != null) {
            _selectedIngredient = _allIngredients.firstWhere(
              (i) => i.name == widget.initialValue,
              orElse: () => IngredientMaster(
                ingredientId: -1,
                name: widget.initialValue!,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _showDropdown = true;
      if (query.isEmpty) {
        _searchResults = _allIngredients;
      } else {
        _searchResults = _allIngredients
            .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectIngredient(IngredientMaster ingredient) {
    setState(() {
      _selectedIngredient = ingredient;
      _searchController.text = ingredient.name;
      _showDropdown = false;
    });
    widget.onSelected(ingredient);
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onTap: () => setState(() => _showDropdown = true),
          style: TextStyle(
            color: widget.isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar o seleccionar ingrediente...',
            hintStyle: TextStyle(
              color: widget.isDark
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.nutveSelectionGreen,
            ),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedIngredient = null;
                        _searchResults = _allIngredients;
                      });
                    },
                  )
                : const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.nutveDarkGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_showDropdown && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isDark ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: widget.isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                final isSelected =
                    _selectedIngredient?.ingredientId == item.ingredientId;

                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.nutveSelectionGreen,
                          size: 18,
                        )
                      : null,
                  onTap: () => _selectIngredient(item),
                );
              },
            ),
          ),
      ],
    );
  }
}
