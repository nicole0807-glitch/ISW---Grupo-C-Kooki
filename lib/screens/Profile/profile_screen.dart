import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Necesario para limpiar el estado
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart'; // Necesario para acceder a clearStatus()
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variable de estado para la animación de carga
  bool _isLoading = false; 

  // --- LÓGICA DE CIERRE DE SESIÓN CORREGIDA ---
  Future<void> _handleLogout() async {
    final authController = AuthController();
    final homeController = context.read<HomeController>();

    setState(() => _isLoading = true);

    try {
      // 1. Ejecutar logout en Supabase
      await authController.logout();
      
      // 2. Limpiar el estado de administrador localmente
      homeController.clearStatus();

      if (mounted) {
        // 3. Navegación limpia al login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e")),
        );
      }
    }
  }

  // --- DISEÑO CIERRE DE SESIÓN ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // Usamos dialogContext para el pop
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("¿Cerrar sesión?"),
          content: const Text("Tu sesión actual finalizará y tendrás que ingresar tus credenciales nuevamente."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), 
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Cerramos el diálogo inmediatamente para liberar el contexto
                Navigator.pop(dialogContext);
                // Ejecutamos la lógica de salida
                _handleLogout();
              },
              child: const Text("SÍ, SALIR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Título de la página
        title: const Text("Mi Perfil"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => {/* Acción Futura */},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () { /* Acción futura */ },
          ),
        ],
      ),
      
      // --- LÓGICA CIERRE DE SESIÓN ---
      // Si _isLoading es true, muestra el círculo.
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TUS PLACEHOLDERS Y DISEÑO ORIGINALES ---
                    const Text("Título (Opcional)", textAlign: TextAlign.center),
                    const SizedBox(height: 100, child: Placeholder(color: Colors.blueGrey)),
                    const SizedBox(height: 20),

                    const Text("Título (Opcional)", textAlign: TextAlign.center),
                    const SizedBox(height: 100, child: Placeholder(color: Colors.teal)),
                    const SizedBox(height: 40),

                    const Text(
                      "Configuración de Cuenta",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    // Botón de información personal
                    _buildMenuButton(
                      text: "Información Personal",
                      icon: Icons.person,
                      baseColor: Colors.blueAccent,
                      onTap: () { print("Info"); },
                    ),
                    
                    _buildMenuButton(
                      text: "Preferencias de Dieta",
                      icon: Icons.flatware,
                      baseColor: Colors.orange,
                      onTap: () { print("Preferencias"); },
                    ),

                    _buildMenuButton(
                      text: "Gestionar Suscripción",
                      icon: Icons.stars,
                      baseColor: Colors.green,
                      onTap: () { print("Suscripción"); },
                    ),

                    // BOTÓN DE CERRAR SESIÓN
                    _buildLogoutButton(
                      text: "Cerrar Sesión",
                      onTap: () {
                        // Llama a la lógica del Dialog
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Widget MenuButton ---
  Widget _buildMenuButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color baseColor = Colors.blue,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: baseColor),
        ),
        title: Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
        onTap: onTap,
      ),
    );
  }

  // --- Widget LogoutButton ---
  Widget _buildLogoutButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.red.shade50, // Fondo rojo pastel
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 10, top: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        )
      )
    );
  }
}