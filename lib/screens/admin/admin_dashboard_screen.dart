import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Asegúrate de tener estas rutas correctas en tu proyecto
import '../../controllers/adminDashboardController.dart';
import '../recipe/admin_recipes_screen.dart';
import '../../services/admin_service.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardController _controller = AdminDashboardController();
  final AdminService _adminService = AdminService(); // <- Añadido el servicio
  bool _isProcessing = false; // <- Estado de carga unificado

  // Paleta de colores del Dashboard
  final Color bgDark = const Color(0xFF1B2521);
  final Color cardDark = const Color(0xFF24302B);
  final Color accentGreen = const Color(0xFF22C55E);
  final Color lightGreen = const Color(0xFFDCFCE7);
  final Color textWhite = Colors.white;
  final Color textGrey = const Color(0xFFA1A1AA);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CARGA (Traída del Control Panel) ---
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

  // --- DIÁLOGO DE NOTIFICACIÓN ADAPTADO AL TEMA OSCURO ---
  void _showCustomNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Aviso a la Comunidad", style: GoogleFonts.poppins(color: textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            TextField(
              controller: titleController,
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: "Título del mensaje",
                labelStyle: TextStyle(color: textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 3,
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: "Contenido del aviso",
                labelStyle: TextStyle(color: textGrey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textGrey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGreen)),
              ),
            ),
          ],
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: GoogleFonts.poppins(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
            child: Text("Enviar", style: GoogleFonts.poppins(color: bgDark, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO ELIMINAR POR ID ---
  void _showDeleteByIdDialog() {
    final idController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Eliminar por ID", style: GoogleFonts.poppins(color: Colors.redAccent)),
        content: TextField(
          controller: idController,
          style: TextStyle(color: textWhite),
          decoration: InputDecoration(
            labelText: "Ingrese el ID exacto",
            labelStyle: TextStyle(color: textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textGrey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
          ),
        ),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: GoogleFonts.poppins(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Aquí pondrías tu lógica de borrado por ID
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Acción de borrado pendiente de implementar")),
              );
            },
            child: Text("Eliminar", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: bgDark,
          body: SafeArea(
            // Usamos un Stack para poner el loader encima de todo sin perder el diseño
            child: Stack(
              children:[
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      _buildHeader(),
                      const SizedBox(height: 40),
                      
                      Text(
                        "Centro de gestión", 
                        style: GoogleFonts.poppins(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 20),
                      
                      _buildManagementHub(context),
                    ],
                  ),
                ),

                // Loader superpuesto
                if (_isProcessing)
                  Container(
                    color: bgDark.withOpacity(0.7),
                    child: Center(
                      child: CircularProgressIndicator(color: accentGreen),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(context),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children:[
        const CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text("Administrador del sistema", style: GoogleFonts.poppins(color: textGrey, fontSize: 12)),

            Text("Panel de Kooki", style: GoogleFonts.poppins(color: textWhite, fontSize: 18, fontWeight: FontWeight.w600)),

          ],
        ),
        const Spacer(),
        Stack(
          children:[
            Icon(Icons.notifications, color: textWhite, size: 28),
            if (_controller.newReports > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              )
          ],
        )
      ],
    );
  }

  Widget _buildManagementHub(BuildContext context) {
    return Column(
      children:[
        // --- BOTONES ORIGINALES DEL DASHBOARD ---

        _buildMenuButton(
          "Gestión de usuarios", 
          "Roles y permisos", 
          Icons.manage_accounts, 
          Colors.blue,
          () {}, 
        ),
        const SizedBox(height: 16),

        _buildMenuButton(
          "CRUD de recetas", 
          "Crear, editar y eliminar", 
          Icons.book, 
          lightGreen,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminRecipesScreen()),
            );
          },
        ),
        const SizedBox(height: 16),

        _buildMenuButton(
          "Moderación", 
          "Contenido reportado y denuncias", 
          Icons.gavel, 
          Colors.orange,
          () {}, 
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Divider(color: Colors.white24, thickness: 1),
        ),
        
        Text(
          "Operaciones del sistema", 
          style: GoogleFonts.poppins(color: textWhite, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),

        // --- BOTONES MIGRADOS DEL CONTROL PANEL ---

        _buildMenuButton(
          "Entrenar IA", 
          "Actualiza el motor de recomendaciones", 
          Icons.psychology, 
          Colors.deepPurpleAccent,
          () => _handleAction(() => _adminService.trainAIModel()),
        ),
        const SizedBox(height: 16),

        _buildMenuButton(
          "Mandar Notificación", 
          "Aviso global para toda la comunidad", 
          Icons.campaign, 
          Colors.amber,
          () => _showCustomNotificationDialog(),
        ),
        const SizedBox(height: 16),

        _buildMenuButton(
          "Eliminar por ID", 
          "Usa esto solo si conoces el ID exacto", 
          Icons.delete_forever, 
          Colors.redAccent,
          () => _showDeleteByIdDialog(),
        ),
        const SizedBox(height: 40), // Espacio extra al final
      ],
    );
  }

  Widget _buildMenuButton(String title, String subtitle, IconData icon, Color iconBg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow:[
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Row(
          children:[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBg == lightGreen ? Colors.white : iconBg, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded( // <-- Evita errores de overflow si el texto es largo
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Text(title, style: GoogleFonts.poppins(color: textWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.poppins(color: textGrey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgDark,
        border: Border(top: BorderSide(color: cardDark, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children:[
                  Icon(Icons.home, color: accentGreen, size: 28),
                  const SizedBox(width: 8),
                  Text("Inicio", style: GoogleFonts.poppins(color: accentGreen, fontWeight: FontWeight.bold)),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}