import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../utils/app_colors.dart';


class DietPreferencesScreen extends StatefulWidget {
  const DietPreferencesScreen({super.key});

  @override
  State<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends State<DietPreferencesScreen> {
  final _profileService = ProfileService();
  
  // Datos de la pantalla
  List<Map<String, dynamic>> _allTags = [];
  List<int> _selectedTagIds = [];
  List<Map<String, dynamic>> _selectedAllergies = []; 
  List<Map<String, dynamic>> _searchResults = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tags = await _profileService.getDietTags();
      final userTags = await _profileService.getUserDietTags();
      final userAllergies = await _profileService.getUserAllergies();
      
      if (!mounted) return;
      setState(() {
        _allTags = tags;
        _selectedTagIds = userTags;
        _selectedAllergies = userAllergies.map((a) => {
          'id': a['ingredient_id'],
          'name': a['Ingredient']['name']
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "No pudimos cargar tus preferencias. Revisa tu conexión.";
      });
    }
  }

  // --- MÉTODOS DE UI (LOS QUE FALTABAN) ---

  // 1. Sección de Etiquetas de Dieta
  Widget _buildTagsWrap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? Colors.white.withOpacity(0.07) : Colors.white;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _allTags.map((tag) {
        final isSelected = _selectedTagIds.contains(tag['tag_id']);
        return FilterChip(
          label: Text(tag['name']),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              selected
                  ? _selectedTagIds.add(tag['tag_id'])
                  : _selectedTagIds.remove(tag['tag_id']);
            });
          },
          backgroundColor: chipBg,
          selectedColor: AppColors.nutveSelectionGreen,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.nutveSelectionGreen
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      }).toList(),
    );
  }

  // 2. Barra de Búsqueda Estilizada
  Widget _buildStyledSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: TextField(
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87
        ),
        onChanged: (val) async {
          if (val.isEmpty) {
            setState(() => _searchResults = []);
            return;
          }
          final results = await _profileService.searchIngredients(val);
          setState(() => _searchResults = results);
        },
        decoration: InputDecoration(
          hintText: "Buscar ingrediente (ej. Tomate)",
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.nutveSelectionGreen),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // 3. Lista de Alergias Seleccionadas
  Widget _buildSelectedAllergiesWrap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedAllergies.map((ing) {
        return Chip(
          label: Text(ing['name']),
          backgroundColor: isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50,
          labelStyle: TextStyle(
            color: isDark ? Colors.redAccent.shade100 : Colors.red.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          deleteIcon: Icon(
            Icons.cancel_rounded,
            size: 18,
            color: isDark ? Colors.redAccent.shade100 : Colors.red.shade700,
          ),
          onDeleted: () {
            setState(() => _selectedAllergies
                .removeWhere((a) => a['ingredient_id'] == ing['ingredient_id']));
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.red.shade100,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 4. Botón de Guardar al fondo
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nutveSelectionGreen,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: _isSaving ? null : _handleSave,
        child: _isSaving 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("GUARDAR PREFERENCIAS", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await _profileService.saveDietaryProfile(
      _selectedTagIds, 
      _selectedAllergies.map((a) => a['ingredient_id'] as int).toList()
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // --- ESTRUCTURA PRINCIPAL (BUILD) ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Preferencias de Dieta",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Botón siempre visible abajo
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: _buildSaveButton(),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorState(_errorMessage!, _loadData)
          : Stack( // Stack global para permitir que el buscador flote y sea clickeable
            children: [
              // Capa 1: El contenido con Scroll
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Etiquetas de Dieta",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTagsWrap(),
                    const SizedBox(height: 35),
                    const Text(
                      "Alergias e Intolerancias",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Si ya seleccionaste una dieta arriba, no es necesario agregar sus ingredientes aquí.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Solo dejamos el espacio de la barra, la lógica flotante está en la Capa 2
                    _buildStyledSearchBar(),

                    const SizedBox(height: 20),
                    _buildSelectedAllergiesWrap(),
                    
                    const SizedBox(height: 100), // Espacio para no chocar con el botón de abajo
                  ],
                ),
              ),

              // Capa 2: RESULTADOS FLOTANTES (Overlay)
              if (_searchResults.isNotEmpty)
                Positioned(
                  // Ajusta este valor si tu barra de búsqueda queda más arriba o abajo
                  top: 290, 
                  left: 20,
                  right: 20,
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final ing = _searchResults[index];
                          return ListTile(
                            title: Text(
                              ing['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.nutveSelectionGreen,
                              size: 20,
                            ),
                            onTap: () {
                              setState(() {
                                if (!_selectedAllergies.any((a) => a['ingredient_id'] == ing['ingredient_id'])) {
                                  _selectedAllergies.add({'ingredient_id': ing['ingredient_id'], 'name': ing['name']});
                                }
                                _searchResults = []; // Limpiar búsqueda para cerrar el overlay
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nutveSelectionGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Intentar de nuevo",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}