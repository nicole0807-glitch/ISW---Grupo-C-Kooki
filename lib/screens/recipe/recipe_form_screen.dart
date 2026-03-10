import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/recipe_controller.dart';
import '../../models/recipe_model.dart';
import '../../models/ingredient_master.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _imgUrlCtrl;
  String? _difficulty;

  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isUrlMode = false;

  final List<String> _difficultyOptions =["Fácil", "Media", "Difícil"];
  List<RecipeIngredient> _ingredients =[];
  List<String> _steps =[];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeAdminController>().loadMasterIngredients();
    });

    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _timeCtrl = TextEditingController(text: r?.cookingTime ?? '');
    _imgUrlCtrl = TextEditingController(text: r?.imageUrl ?? '');

    if (r?.imageUrl != null && r!.imageUrl!.isNotEmpty) {
      _isUrlMode = true;
    }

    if (r?.difficulty != null && _difficultyOptions.contains(r!.difficulty)) {
      _difficulty = r.difficulty;
    } else {
      _difficulty = null;
    }

    if (r != null) {
      _ingredients = List.from(r.ingredients);
      _steps = List.from(r.steps);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedFileName = image.name;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUrlMode) {
      _selectedImageBytes = null;
      _selectedFileName = null;
    } else {
      _imgUrlCtrl.clear();
    }

    if ((!_isUrlMode && _selectedImageBytes == null) ||
        (_isUrlMode && _imgUrlCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes agregar una imagen (Sube un archivo o pega una URL)")),
      );
      return;
    }

    if (_ingredients.isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añade al menos un ingrediente y un paso")),
      );
      return;
    }

    final recipeToProcess = Recipe(
      id: widget.recipe?.id ?? 0,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      imageUrl: _imgUrlCtrl.text,
      cookingTime: _timeCtrl.text,
      difficulty: _difficulty,
      nutrition: widget.recipe?.nutrition ?? {},
      ingredients: _ingredients,
      steps: _steps,
      tagIds: widget.recipe?.tagIds ??[],
      rating: widget.recipe?.rating ?? 0.0,
      status: widget.recipe?.status ?? 'pendiente',
    );

    final success = await context.read<RecipeAdminController>().createOrUpdateRecipe(
          recipeToProcess,
          isEdit: widget.recipe != null,
          imageBytes: _selectedImageBytes,
          fileName: _selectedFileName,
        );

    if (success && mounted) Navigator.pop(context);
  }

  // --- NUEVA LÓGICA DEL DIÁLOGO (MÁS LIMPIA Y SEGURA) ---
  void _addIngredientDialog() async {
    final controller = context.read<RecipeAdminController>();
    
    // Abrimos el Diálogo extraído y esperamos su resultado
    final newIngredient = await showDialog<RecipeIngredient>(
      context: context,
      builder: (ctx) => _IngredientSearchDialog(controller: controller),
    );

    // Si el usuario guardó un ingrediente, lo agregamos a la lista
    if (newIngredient != null) {
      setState(() {
        _ingredients.add(newIngredient);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();
    final accentGreen = const Color(0xFF13EC5B);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? "Nueva Receta" : "Editar Receta"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(
                "Imagen de la Receta",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),

              Row(
                children:[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUrlMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isUrlMode ? accentGreen.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: !_isUrlMode ? accentGreen : Colors.grey.shade300),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text("Subir Archivo",
                            style: TextStyle(fontWeight: FontWeight.bold, color: !_isUrlMode ? Colors.green[800] : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUrlMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isUrlMode ? accentGreen.withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: _isUrlMode ? accentGreen : Colors.grey.shade300),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text("Usar URL",
                            style: TextStyle(fontWeight: FontWeight.bold, color: _isUrlMode ? Colors.green[800] : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_isUrlMode) ...[
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const[
                                Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("Toca para subir desde galería", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _imgUrlCtrl,
                  decoration: InputDecoration(
                    labelText: "Pega el URL de la imagen",
                    hintText: "https://ejemplo.com/imagen.jpg",
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (_imgUrlCtrl.text.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _imgUrlCtrl.text,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const[
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("URL inválido o imagen no encontrada", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Título de la Receta",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) => v!.isEmpty ? "El título es obligatorio" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Descripción corta",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children:[
                  Expanded(
                    child: TextFormField(
                      controller: _timeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Tiempo (min)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      items: _difficultyOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _difficulty = v),
                      decoration: const InputDecoration(
                        labelText: "Dificultad",
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (v) => v == null ? "Requerido" : null,
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),
              _sectionHeader("Ingredientes", _addIngredientDialog),
              ..._ingredients.asMap().entries.map(
                (e) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${e.value.amount} ${e.value.unit}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _ingredients.removeAt(e.key)),
                    ),
                  ),
                ),
              ),

              const Divider(height: 40),
              _sectionHeader("Pasos de Preparación", () {
                String step = '';
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Nuevo Paso"),
                    content: TextField(
                      onChanged: (v) => step = v,
                      decoration: const InputDecoration(hintText: "Escribe la instrucción..."),
                    ),
                    actions:[
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                      ElevatedButton(
                        onPressed: () {
                          if (step.isNotEmpty) setState(() => _steps.add(step));
                          Navigator.pop(ctx);
                        },
                        child: const Text("Añadir"),
                      ),
                    ],
                  ),
                );
              }),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (oldIdx < newIdx) newIdx -= 1;
                    final item = _steps.removeAt(oldIdx);
                    _steps.insert(newIdx, item);
                  });
                },
                children:[
                  for (int i = 0; i < _steps.length; i++)
                    ListTile(
                      key: ValueKey("step_$i"),
                      leading: CircleAvatar(
                        backgroundColor: accentGreen,
                        radius: 12,
                        child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(_steps[i]),
                      trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: controller.isLoading ? null : _submit,
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          widget.recipe == null ? "CREAR RECETA" : "ACTUALIZAR RECETA",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:[
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle, color: Color(0xFF13EC5B), size: 28),
        ),
      ],
    );
  }
}
// =========================================================================
// WIDGET EXTRAÍDO PARA EVITAR FUGAS DE MEMORIA Y PANTALLAS BLANCAS
// =========================================================================
class _IngredientSearchDialog extends StatefulWidget {
  final RecipeAdminController controller;

  const _IngredientSearchDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<_IngredientSearchDialog> createState() => _IngredientSearchDialogState();
}

class _IngredientSearchDialogState extends State<_IngredientSearchDialog> {
  late TextEditingController _searchCtrl;
  late TextEditingController _amountCtrl;

  String _selectedUnit = 'g';
  final List<String> _units = ['g', 'kg', 'mL', 'L', 'Piezas', 'Tazas'];

  List<IngredientMaster> _searchResults =[];
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _searchResults = widget.controller.masterIngredients;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Añadir Ingrediente"),
      content: SizedBox(
        width: double.maxFinite, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              TextField(
                controller: _searchCtrl,
                // 🟢 1. MANEJO MANUAL: Abre la lista al tocar el campo
                onTap: () {
                  setState(() {
                    _showDropdown = true;
                    _searchResults = widget.controller.searchMasterIngredients(_searchCtrl.text);
                  });
                },
                decoration: InputDecoration(
                  labelText: "Nombre del ingrediente",
                  hintText: "Buscar o crear nuevo...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                              _searchResults = widget.controller.masterIngredients;
                              _showDropdown = true;
                            });
                          },
                        )
                      : const Icon(Icons.arrow_drop_down),
                ),
                onChanged: (query) {
                  setState(() {
                    _showDropdown = true;
                    _searchResults = widget.controller.searchMasterIngredients(query);
                  });
                },
              ),

              if (_showDropdown && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow:[
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    // 🟢 2. FÍSICA DE SCROLL: Evita que el scroll cancele el toque
                    physics: const ClampingScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(item.name),
                        onTap: () {
                          // 🟢 3. SELECCIÓN SEGURA: Cierra el teclado y la lista
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _searchCtrl.text = item.name;
                            _showDropdown = false;
                          });
                        },
                      );
                    },
                  ),
                ),

              if (_showDropdown && _searchResults.isEmpty && _searchCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children:[
                      const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El ingrediente es nuevo. Se creará automáticamente al guardar.',
                          style: TextStyle(color: Colors.blue[700], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      // 🟢 4. CERRAR LISTA: Si tocan la cantidad, ocultamos las sugerencias
                      onTap: () {
                        if (_showDropdown) {
                          setState(() => _showDropdown = false);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Cantidad",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: "Unidad",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedUnit = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions:[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () {
            final name = _searchCtrl.text.trim();
            final amount = _amountCtrl.text.trim();
            if (name.isNotEmpty && amount.isNotEmpty) {
              Navigator.pop(
                context,
                RecipeIngredient(
                  ingredientId: 0,
                  name: name,
                  amount: double.tryParse(amount) ?? 0,
                  unit: _selectedUnit,
                ),
              );
            }
          },
          child: const Text("Añadir"),
        ),
      ],
    );
  }
}