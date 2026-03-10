import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Asegúrate de tener estas rutas correctas en tu proyecto
import '../../controllers/adminDashboardController.dart';
import '../recipe/admin_recipes_screen.dart';
import '../../services/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';

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
        title: Text(
          "Aviso a la Comunidad",
          style: GoogleFonts.poppins(color: textWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: textWhite),
              decoration: InputDecoration(
                labelText: "Título del mensaje",
                labelStyle: TextStyle(color: textGrey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textGrey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentGreen),
                ),
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
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textGrey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: GoogleFonts.poppins(color: textGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            child: Text(
              "Enviar",
              style: GoogleFonts.poppins(
                color: bgDark,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        title: Text(
          "Eliminar por ID",
          style: GoogleFonts.poppins(color: Colors.redAccent),
        ),
        content: TextField(
          controller: idController,
          style: TextStyle(color: textWhite),
          decoration: InputDecoration(
            labelText: "Ingrese el ID exacto",
            labelStyle: TextStyle(color: textGrey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textGrey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: GoogleFonts.poppins(color: textGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // Aquí pondrías tu lógica de borrado por ID
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Acción de borrado pendiente de implementar"),
                ),
              );
            },
            child: Text(
              "Eliminar",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE ENTRENAMIENTO IA ---
  void _showTrainAIDialog() {
    final keywordsController = TextEditingController();
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.deepPurpleAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              "Entrenar Kooki AI",
              style: GoogleFonts.poppins(
                color: textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enseña a la IA a responder a palabras específicas. Separa las palabras clave por comas.",
                style: GoogleFonts.poppins(color: textGrey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: keywordsController,
                style: TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: "Palabras clave (ej: dieta, calorías)",
                  labelStyle: TextStyle(color: textGrey),
                  prefixIcon: Icon(Icons.key, color: Colors.deepPurpleAccent),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                maxLines: 4,
                style: TextStyle(color: textWhite),
                decoration: InputDecoration(
                  labelText: "Respuesta de Mitroglu",
                  labelStyle: TextStyle(color: textGrey),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Icon(
                      Icons.chat_bubble,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  filled: true,
                  fillColor: bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (keywordsController.text.isNotEmpty &&
                  responseController.text.isNotEmpty) {
                Navigator.pop(context);
                _handleAction(
                  () => _adminService.trainAIModelWithData(
                    keywordsController.text,
                    responseController.text,
                  ),
                );
              }
            },
            child: const Text(
              "Entrenar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgDark,
                  const Color(0xFF161D1A),
                  const Color(0xFF0F1412),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        Text(
                          "Gestión Principal",
                          style: GoogleFonts.poppins(
                            color: textWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildManagementHub(context),
                      ],
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: accentGreen),
                            const SizedBox(height: 16),
                            Text(
                              "Procesando...",
                              style: GoogleFonts.poppins(color: textWhite),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(context),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          "Reportes",
          _controller.newReports.toString(),
          Icons.warning_amber,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          "Usuarios",
          _controller.activeUsers,
          Icons.people,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(color: textGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [accentGreen, Colors.blueAccent]),
          ),
          child: const CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Panel de Control",
              style: GoogleFonts.poppins(
                color: accentGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "Hola, Admin 👋",
              style: GoogleFonts.poppins(
                color: textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildIconButton(Icons.notifications_outlined, () {}),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: IconButton(
        icon: Icon(icon, color: textWhite, size: 24),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildManagementHub(BuildContext context) {
    return Column(
      children: [
        _buildModernMenuButton(
          "Usuarios y Roles",
          "Gestionar accesos y permisos",
          Icons.group_add_rounded,
          [Colors.blue, Colors.blueAccent],
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminUsersScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildModernMenuButton(
          "Biblioteca de Recetas",
          "Contenido oficial y de usuario",
          Icons.restaurant_menu_rounded,
          [accentGreen, const Color(0xFF15803D)],
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminRecipesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildModernMenuButton(
          "Moderación activa",
          "Revisar denuncias pendientes",
          Icons.verified_user_rounded,
          [Colors.orange, Colors.deepOrange],
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminReportsScreen(),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Divider(color: Colors.white10),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Inteligencia Artificial",
            style: GoogleFonts.poppins(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildModernMenuButton(
          "Entrenar Mitroglu AI",
          "Nuevas palabras y conocimientos",
          Icons.auto_awesome_rounded,
          [Colors.deepPurple, Colors.purpleAccent],
          () => _showTrainAIDialog(),
        ),
        const SizedBox(height: 16),
        _buildModernMenuButton(
          "Aviso Comunitario",
          "Notificación global push",
          Icons.sensors_rounded,
          [Colors.amber, Colors.orangeAccent],
          () => _showCustomNotificationDialog(),
        ),
        const SizedBox(height: 16),
        _buildModernMenuButton(
          "Acciones de Limpieza",
          "Eliminación forzada por ID",
          Icons.auto_delete_rounded,
          [Colors.redAccent, Colors.red.shade900],
          () => _showDeleteByIdDialog(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildModernMenuButton(
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textGrey.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bgDark,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGreen.withOpacity(0.2), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_rounded, color: accentGreen),
                const SizedBox(width: 12),
                Text(
                  "Dashboard",
                  style: GoogleFonts.poppins(
                    color: accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
