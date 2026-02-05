import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variable de estado para la animación de carga
  bool _isLoading = false; 

  // --- DISEÑO CIERRE DE SESIÓN ---
  void _showLogoutDialog(BuildContext context) {
    // Controlador Auth
    final AuthController authController = AuthController(); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("¿Cerrar sesión?"),
          content: const Text("Tu sesión actual finalizará y tendrás que ingresar tus credenciales nuevamente."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                // Cerrar alerta
                Navigator.pop(context);
                
                // Ejecución de la animacion
                setState(() {
                  _isLoading = true;
                });
                
                // Espera hasta que se cierre la sesión
                await authController.logout();
                
                // Ir al login screen
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
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
                    // --- TUS PLACEHOLDERS Y DISEÑO ---
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
            color: baseColor.withValues(alpha: 0.15),
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
              textAlign: TextAlign.center, // Alineamos el texto dentro de ese espacio infinito
              style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            )
          )
        )
      )
    );
  }
}