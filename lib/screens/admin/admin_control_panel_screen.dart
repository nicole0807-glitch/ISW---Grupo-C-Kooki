import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/admin_service.dart';

class AdminControlPanelScreen extends StatefulWidget {
  const AdminControlPanelScreen({super.key});

  @override
  State<AdminControlPanelScreen> createState() =>
      _AdminControlPanelScreenState();
}

class _AdminControlPanelScreenState extends State<AdminControlPanelScreen> {
  final AdminService _adminService = AdminService();
  bool _isProcessing = false;

  // --- 1. DIÁLOGO PARA NOTIFICACIONES PERSONALIZADAS ---
  void _showCustomNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Enviar Aviso a la Comunidad"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Título del mensaje",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Contenido del aviso",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleAction(
                  () => _adminService.sendGlobalNotification(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
              }
            },
            child: const Text("Enviar Notificación"),
          ),
        ],
      ),
    );
  }

  // --- 2. FORMULARIO PARA AÑADIR RECETA PROFESIONAL ---
  void _showAddProRecipeForm() {
    final titleController = TextEditingController();
    final specialistController = TextEditingController();
    final caloriesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nueva Receta Profesional",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Simulación de selector de imagen
              Center(
                child: GestureDetector(
                  onTap: () {
                    /* Aquí conectarías con ImagePicker */
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40),
                        Text("Subir Foto"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Título de la Receta",
                ),
              ),
              TextField(
                controller: specialistController,
                decoration: const InputDecoration(
                  labelText: "Especialista (Chef/Nutricionista)",
                ),
              ),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(labelText: "Kcal (Opcional)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nutveDarkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _handleAction(
                      () => _adminService.addProfessionalRecipe({
                        'title': titleController.text,
                        'author_name': specialistController.text,
                        'calories': caloriesController.text,
                        'image_url':
                            'https://placehold.co/600x400.png', // Placeholder
                      }),
                    );
                  },
                  child: const Text(
                    "PUBLICAR Y NOTIFICAR",
                    style: TextStyle(color: Colors.white),
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

  // --- LÓGICA DE CARGA ---
  Future<void> _handleAction(Future<void> Function() action) async {
    setState(() => _isProcessing = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acción realizada con éxito"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consola Maestra Admin"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.nutveDarkGreen),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildCard(
                  "Entrenar IA",
                  "Actualiza el motor de recomendaciones con datos nuevos",
                  Icons.psychology,
                  Colors.deepPurple,
                  () => _handleAction(() => _adminService.trainAIModel()),
                ),
                _buildCard(
                  "Mandar Notificación",
                  "Escribe un aviso global para toda la comunidad",
                  Icons.campaign,
                  Colors.orange,
                  () => _showCustomNotificationDialog(),
                ),
                _buildCard(
                  "Añadir Receta Pro",
                  "Crea contenido oficial con firma de especialista",
                  Icons.verified,
                  AppColors.nutveDarkGreen,
                  () => _showAddProRecipeForm(),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(),
                ),
                const Text(
                  "Gestión de Borrado",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCard(
                  "Eliminar por ID",
                  "Usa esto solo si conoces el ID exacto",
                  Icons.delete_forever,
                  Colors.red,
                  () {
                    /* Puedes reusar el diálogo de ID de mensajes anteriores */
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
