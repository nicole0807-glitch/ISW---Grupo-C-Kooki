import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importante para Auth
import '../../utils/app_colors.dart';
import '../../models/user_recipe_model.dart';
import '../../services/recipe_service.dart';

class PublishRecipeScreen extends StatefulWidget {
  const PublishRecipeScreen({super.key});

  @override
  State<PublishRecipeScreen> createState() => _PublishRecipeScreenState();
}

class _PublishRecipeScreenState extends State<PublishRecipeScreen> {
  final RecipeService _recipeService = RecipeService();
  final SupabaseClient supabase = Supabase.instance.client;

  // Controladores de texto
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionController = TextEditingController();

  // Selectores de Dificultad y Costo
  String _difficulty = 'Medio';
  String _cost = 'Medio';

  // Lista dinámica de ingredientes
  List<Map<String, TextEditingController>> _ingredientRows = [
    {'name': TextEditingController(), 'amount': TextEditingController()},
  ];

  Uint8List? _selectedImageBytes;
  String? _imageName;
  bool _isUploading = false;

  void _showAssistantAviso(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.redAccent : AppColors.nutveDarkGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/assistant.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        _imageName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  void _addIngredient() => setState(
    () => _ingredientRows.add({
      'name': TextEditingController(),
      'amount': TextEditingController(),
    }),
  );

  void _removeIngredient(int index) {
    if (_ingredientRows.length > 1) {
      setState(() => _ingredientRows.removeAt(index));
    } else {
      _showAssistantAviso("¡Necesito al menos un ingrediente!");
    }
  }

  // --- LÓGICA DE PUBLICACIÓN ACTUALIZADA CON USERNAME ---
  Future<void> _handlePublish() async {
    if (_titleController.text.trim().isEmpty || _selectedImageBytes == null) {
      _showAssistantAviso(
        "¡Hola! Necesito un título y una foto.",
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Obtener usuario actual y su nombre real
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No hay sesión activa.");

      // Buscamos el nombre en los metadatos (Google o Registro Manual)
      final String realUserName =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['display_name'] ??
          'Chef Nutve';

      // 2. Subir Foto
      final String? imageUrl = await _recipeService.uploadRecipeImage(
        _selectedImageBytes!,
        _imageName!,
      );

      if (imageUrl == null) throw Exception("Error al guardar la imagen.");

      // 3. Formatear ingredientes
      final ingredientsList = _ingredientRows
          .where((e) => e['name']!.text.isNotEmpty)
          .map((e) => {'name': e['name']!.text, 'amount': e['amount']!.text})
          .toList();

      // 4. Crear objeto con el userName obtenido de Auth
      final newRecipe = UserRecipe(
        userId: user.id,
        userName: realUserName, // <--- AQUÍ SE ASIGNA EL NOMBRE REAL
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        duration: _durationController.text.isEmpty
            ? "15 min"
            : _durationController.text,
        cost: _cost,
        difficulty: _difficulty,
        instructions: _instructionController.text.trim(),
        ingredients: ingredientsList,
        steps: [_instructionController.text.trim()],
        nutrition: {},
      );

      // 5. Guardar en DB
      await _recipeService.saveRecipe(newRecipe);

      _showAssistantAviso("¡Genial! Tu receta ya está disponible.");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showAssistantAviso("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Publicar Receta"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isUploading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.nutveDarkGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageArea(),
                  const SizedBox(height: 25),
                  _buildLabel("Título de la receta"),
                  const SizedBox(height: 8),
                  _buildTextField(_titleController, "Ej: Pasta al Pesto"),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          "Dificultad",
                          ['Bajo', 'Medio', 'Alto'],
                          _difficulty,
                          (v) => setState(() => _difficulty = v!),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildDropdown(
                          "Costo",
                          ['Poco', 'Medio', 'Muy'],
                          _cost,
                          (v) => setState(() => _cost = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Duración aproximada"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _durationController,
                    "Ej: 15 min",
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 30),
                  _buildIngredientSection(),
                  const SizedBox(height: 30),
                  _buildLabel("Pasos de preparación"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _instructionController,
                    "Describe la preparación...",
                    maxLines: 5,
                  ),
                  const SizedBox(height: 40),
                  _buildPublishButton(),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildLabel(String t) => Text(
    t,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          image: _selectedImageBytes != null
              ? DecorationImage(
                  image: MemoryImage(_selectedImageBytes!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                  Text(
                    "Añadir foto de la receta",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("Ingredientes"),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text("Añadir"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.nutveDarkGreen,
              ),
            ),
          ],
        ),
        ..._ingredientRows.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(entry.value['name']!, "Ingrediente"),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildTextField(entry.value['amount']!, "Cant."),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _removeIngredient(entry.key),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPublishButton() {
    return ElevatedButton(
      onPressed: _handlePublish,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.nutveDarkGreen,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text(
        "PUBLICAR AHORA",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
