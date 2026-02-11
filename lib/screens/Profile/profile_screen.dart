// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:kooki/services/supabase_service.dart';
import 'package:provider/provider.dart'; // Necesario para limpiar el estado
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart'; // Necesario para acceder a clearStatus()
import '../auth/login_screen.dart';
import '../../services/profile_service.dart';

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
     context.read<HomeController>().clearStatus(); 
    
    // 2. Sign out de Supabase
    final supabaseService = SupabaseService(); 
    await supabaseService.signOut();
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

  //Variables de sesión
  String? _userName;
  String? _avatarURL;

  //Instancia del backen de profile
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserData(); //Función de abajo
  }

  //Función para cargar los datos del usuario
  Future<void> _loadUserData() async {
    //Si no hay usuario logueado no se ejecuta
    if (!_profileService.isUserLoggedIn) {
      setState(() {
      _userName = "Desarrollador Test";
      _avatarURL = "https://i.pravatar.cc/300"; // Una imagen aleatoria de internet
      });
      return;
    }

    //Si hay usuario registrado se obtienen sus datos
    final data = await _profileService.getProfileData();

    if (data != null && mounted) {
      //Se asignan los datos a las variables:
      _userName = data['username'] ?? 'Usuario';
      _avatarURL = data['avatar_url'];
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
    //Si el usuario no está registrado se muestra una pantalla de registro

    
    if (!_profileService.isUserLoggedIn) {
      return _buildGuestView(context);
    }
    

    return Scaffold(
      
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

  // -- Widget Información del perfil --
  Widget _buildProfileHeader() {
    //Obtener el email desde el backend
    final String email = _profileService.currentUser?.email ?? 'no email';

    return Column (
      children: [
        //Avatar del usuario
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _avatarURL != null ? NetworkImage(_avatarURL!) : null,
          child: _avatarURL == null
            ? const Icon(Icons.person, size: 50, color: Colors.grey)
            : null,
        ),
        // Username
        const SizedBox(height: 16),
        Text(
          _userName ?? "Cargando...",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        //email
        Text(
          email,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ]
    );
  }
  
  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Icono de perfil cerrado
              Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey.shade300),
              const SizedBox(height: 20),

              const Text(
                "Guarda tus recetas favoritas y gestiona tu despensa personalizando tu perfil.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black)
              ),
              const SizedBox(height: 40),

              //Botón de login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13EC5B),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    //Ir al login
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                  )
                )
              )

            ]
          )
        )
      )
    );
  }
    

}