import 'package:flutter/material.dart';
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

  // 1. Definimos la lista maestra de opciones permitidas (Coincide con el SQL Constraint)
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
    
    // 2. SEGURIDAD: Validar que el valor de la DB exista en nuestra lista
    // Esto evita la pantalla roja si el dato viene nulo o incorrecto
    if (r?.difficulty != null && _difficultyOptions.contains(r!.difficulty)) {
      _difficulty = r.difficulty;
    } else {
      _difficulty = null; // O _difficultyOptions.first si prefieres un valor por defecto
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añade al menos un ingrediente y un paso")),
      );
      return;
    }

    final newRecipe = Recipe(
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
      status: widget.recipe?.status ?? 'pendiente', // Preservamos el estado actual
    );

    final success = await context
        .read<RecipeAdminController>()
        .createOrUpdateRecipe(newRecipe, isEdit: widget.recipe != null);

    if (success && mounted) Navigator.pop(context);
  }

  void _addIngredientDialog() {
    String name = '';
    String amount = '';
    String unit = 'g';

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Añadir Ingrediente"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(decoration: const InputDecoration(labelText: "Nombre"), onChanged: (v) => name = v),
        TextField(decoration: const InputDecoration(labelText: "Cantidad"), keyboardType: TextInputType.number, onChanged: (v) => amount = v),
        TextField(decoration: const InputDecoration(labelText: "Unidad (ej: g, ml, pza)"), onChanged: (v) => unit = v),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
          if (name.isNotEmpty && amount.isNotEmpty) {
            setState(() {
              _ingredients.add(RecipeIngredient(
                name: name, 
                amount: double.tryParse(amount) ?? 0, 
                unit: unit
              ));
            });
            Navigator.pop(ctx);
          }
        }, child: const Text("Añadir")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeAdminController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? "Nueva Receta" : "Editar Receta"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _titleCtrl, 
              decoration: const InputDecoration(labelText: "Título", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), 
              validator: (v) => v!.isEmpty ? "El título es obligatorio" : null
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl, 
              decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), 
              maxLines: 2
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _timeCtrl, 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Tiempo (min)", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))
              )),
              const SizedBox(width: 16),
              Expanded(child: DropdownButtonFormField<String>(
                value: _difficulty,
                // 3. Usamos la lista de opciones sanitizada
                items: _difficultyOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _difficulty = v),
                decoration: const InputDecoration(labelText: "Dificultad", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                validator: (v) => v == null ? "Selecciona una dificultad" : null,
              )),
            ]),
            
            const Divider(height: 40),
            _sectionHeader("Ingredientes", _addIngredientDialog),
            ..._ingredients.asMap().entries.map((e) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                dense: true,
                title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${e.value.amount} ${e.value.unit}"),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _ingredients.removeAt(e.key))),
              ),
            )),

            const Divider(height: 40),
            _sectionHeader("Pasos de Preparación", () {
              String step = '';
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text("Nuevo Paso"),
                content: TextField(onChanged: (v) => step = v, decoration: const InputDecoration(hintText: "Escribe la instrucción...")),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                  ElevatedButton(onPressed: () { 
                    if(step.isNotEmpty) setState(() => _steps.add(step)); 
                    Navigator.pop(ctx); 
                  }, child: const Text("Añadir"))
                ],
              ));
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
                    leading: CircleAvatar(backgroundColor: const Color(0xFF13EC5B), radius: 12, child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold))),
                    title: Text(_steps[i]),
                    trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                  )
              ],
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC5B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: controller.isLoading ? null : _submit,
                child: controller.isLoading 
                  ? const CircularProgressIndicator(color: Colors.black) 
                  : Text(widget.recipe == null ? "CREAR RECETA" : "ACTUALIZAR RECETA", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle, color: Color(0xFF13EC5B), size: 28)),
    ]);
  }
}