import 'package:flutter/material.dart';
import '../../services/profile_service.dart';


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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tags = await _profileService.getDietTags();
      final userTags = await _profileService.getUserDietTags();
      final userAllergies = await _profileService.getUserAllergies();
      
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
      setState(() => _isLoading = false);
    }
  }

  // --- MÉTODOS DE UI (LOS QUE FALTABAN) ---

  // 1. Sección de Etiquetas de Dieta
  Widget _buildTagsWrap() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _allTags.map((tag) {
        final isSelected = _selectedTagIds.contains(tag['tag_id']);
        return FilterChip(
          label: Text(tag['name']),
          selected: isSelected,
          backgroundColor: Colors.white,
          selectedColor: Color.fromARGB(255, 103, 228, 145),
          checkmarkColor: Colors.black,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            setState(() {
              selected ? _selectedTagIds.add(tag['tag_id']) : _selectedTagIds.remove(tag['tag_id']);
            });
          },
        );
      }).toList(),
    );
  }

  // 2. Barra de Búsqueda Estilizada
  Widget _buildStyledSearchBar() {
    return TextField(
      style: const TextStyle(fontSize: 14),
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
        prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromARGB(255, 103, 228, 145), width: 1.5),
        ),
      ),
    );
  }

  // 3. Lista de Alergias Seleccionadas
  Widget _buildSelectedAllergiesWrap() {
    return Wrap(
      spacing: 8,
      children: _selectedAllergies.map((ing) => Chip(
        label: Text(ing['name']),
        backgroundColor: Colors.red.shade50,
        labelStyle: const TextStyle(color: Colors.red, fontSize: 13),
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
        onDeleted: () {
          setState(() => _selectedAllergies.removeWhere((a) => a['ingredient_id'] == ing['ingredient_id']));
        },
      )).toList(),
    );
  }

  // 4. Botón de Guardar al fondo
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 103, 228, 145),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Preferencias de Dieta"),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
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
        : Stack( // Stack global para permitir que el buscador flote y sea clickeable
            children: [
              // Capa 1: El contenido con Scroll
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Etiquetas de Dieta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTagsWrap(),
                    
                    const SizedBox(height: 35),
                    const Text("Alergias e Intolerancias", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text(
                      "Si ya seleccionaste una dieta arriba, no es necesario agregar sus ingredientes aquí.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    color: Colors.white,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final ing = _searchResults[index];
                          return ListTile(
                            title: Text(ing['name']),
                            trailing: const Icon(Icons.add, color: Colors.blueAccent, size: 20),
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
}