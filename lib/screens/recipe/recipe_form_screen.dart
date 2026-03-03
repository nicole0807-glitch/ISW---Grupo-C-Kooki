import 'dart:typed_data'; // Necesario para compatibilidad Web/Móvil
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kooki/controllers/recipe_controller.dart';
import 'package:kooki/models/recipe_model.dart';

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

  // Variables para la imagen
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;

  // Novedad: Interruptor para saber qué método usar
  bool _isUrlMode = false;

  final List<String> _difficultyOptions = ["Fácil", "Media", "Difícil"];
  List<RecipeIngredient> _ingredients = [];
  List<String> _steps = [];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _timeCtrl = TextEditingController(text: r?.cookingTime ?? '');
    _imgUrlCtrl = TextEditingController(text: r?.imageUrl ?? '');

    // Si la receta ya tiene un URL al editar, abrimos en modo URL
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

  // Selección de imagen: Solo Galería
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

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

    // Novedad: Limpiar la opción no seleccionada para no enviar datos contradictorios
    if (_isUrlMode) {
      _selectedImageBytes = null;
      _selectedFileName = null;
    } else {
      _imgUrlCtrl.clear();
    }

    // Validación de imagen actualizada
    if ((!_isUrlMode && _selectedImageBytes == null) ||
        (_isUrlMode && _imgUrlCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debes agregar una imagen (Sube un archivo o pega una URL)",
          ),
        ),
      );
      return;
    }

    if (_ingredients.isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Añade al menos un ingrediente y un paso"),
        ),
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
      tagIds: widget.recipe?.tagIds ?? [],
      rating: widget.recipe?.rating ?? 0.0,
      status: widget.recipe?.status ?? 'pendiente',
    );

    final success = await context
        .read<RecipeAdminController>()
        .createOrUpdateRecipe(
          recipeToProcess,
          isEdit: widget.recipe != null,
          imageBytes: _selectedImageBytes,
          fileName: _selectedFileName,
        );

    if (success && mounted) Navigator.pop(context);
  }

  void _addIngredientDialog() {
    String name = '';
    String amount = '';
    String unit = 'g';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Añadir Ingrediente"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Nombre"),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Cantidad"),
              keyboardType: TextInputType.number,
              onChanged: (v) => amount = v,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: "Unidad (ej: g, ml, pza)",
              ),
              onChanged: (v) => unit = v,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && amount.isNotEmpty) {
                setState(() {
                  _ingredients.add(
                    RecipeIngredient(
                      ingredientId:
                          0, // Resolto al guardar en Supabase via _insertRelations
                      name: name,
                      amount: double.tryParse(amount) ?? 0,
                      unit: unit,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
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
            children: [
              // --- SECCIÓN DE IMAGEN ---
              Text(
                "Imagen de la Receta",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              // 1. SELECTOR DE MODO (Archivo vs URL)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUrlMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isUrlMode
                              ? accentGreen.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: !_isUrlMode
                                ? accentGreen
                                : Colors.grey.shade300,
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Subir Archivo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isUrlMode
                                  ? Colors.green[800]
                                  : Colors.grey,
                            ),
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
                          color: _isUrlMode
                              ? accentGreen.withOpacity(0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: _isUrlMode
                                ? accentGreen
                                : Colors.grey.shade300,
                          ),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "Usar URL",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isUrlMode
                                  ? Colors.green[800]
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. CONTENIDO CONDICIONAL (Muestra uno u otro)
              if (!_isUrlMode) ...[
                // MODO SUBIR ARCHIVO
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
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Toca para subir desde galería",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ] else ...[
                // MODO URL
                TextFormField(
                  controller: _imgUrlCtrl,
                  decoration: InputDecoration(
                    labelText: "Pega el URL de la imagen",
                    hintText: "https://ejemplo.com/imagen.jpg",
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() {}), // Dispara el render de la vista previa
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
                          children: const [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "URL inválido o imagen no encontrada",
                              style: TextStyle(color: Colors.grey),
                            ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) =>
                    v!.isEmpty ? "El título es obligatorio" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: "Descripción corta",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Tiempo (min)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      items: _difficultyOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _difficulty = v),
                      decoration: const InputDecoration(
                        labelText: "Dificultad",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
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
                    title: Text(
                      e.value.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${e.value.amount} ${e.value.unit}"),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _ingredients.removeAt(e.key)),
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
                      decoration: const InputDecoration(
                        hintText: "Escribe la instrucción...",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar"),
                      ),
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
                children: [
                  for (int i = 0; i < _steps.length; i++)
                    ListTile(
                      key: ValueKey("step_$i"),
                      leading: CircleAvatar(
                        backgroundColor: accentGreen,
                        radius: 12,
                        child: Text(
                          "${i + 1}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(_steps[i]),
                      trailing: const Icon(
                        Icons.drag_handle,
                        color: Colors.grey,
                      ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: controller.isLoading ? null : _submit,
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          widget.recipe == null
                              ? "CREAR RECETA"
                              : "ACTUALIZAR RECETA",
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
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(
            Icons.add_circle,
            color: Color(0xFF13EC5B),
            size: 28,
          ),
        ),
      ],
    );
  }
}
