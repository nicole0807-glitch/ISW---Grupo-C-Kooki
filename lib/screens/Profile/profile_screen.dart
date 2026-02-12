// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kooki/services/supabase_service.dart';
import 'package:provider/provider.dart'; // Necesario para limpiar el estado
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/goal_controller.dart'; 
import '../auth/login_screen.dart';
import '../../services/profile_service.dart';
import '../goals/goal_registration_screen.dart';
import '../recipe/widgets/macro_chart_widget.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _userName;
  String? _avatarURL;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- CARGA DE DATOS ---

  Future<void> _loadUserData() async {
    if (!_profileService.isUserLoggedIn) {
      setState(() {
        _userName = "Desarrollador Test";
        _avatarURL = "https://i.pravatar.cc/300";
      });
      return;
    }

    final data = await _profileService.getProfileData();
    if (data != null && mounted) {
      setState(() {
        _userName = data['username'] ?? 'Usuario';
        _avatarURL = data['avatar_url'];
      });
    }
  }

  // MÉTODO PARA REINICIAR / REFRESCAR DATOS (HU-27)
  Future<void> _refreshGoals(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalRegistrationScreen()),
    );
    
    // Al volver, forzamos la recarga de las metas
    if (mounted) {
      context.read<GoalController>().loadExistingGoals();
    }
  }

  // --- LÓGICA DE CIERRE DE SESIÓN ---

  Future<void> _handleLogout() async {
    final authController = AuthController();
    final homeController = context.read<HomeController>();

    setState(() => _isLoading = true);

    try {
      await authController.logout();
      homeController.clearStatus();

      // 1. Ejecutar logout en Supabase
     context.read<HomeController>().clearStatus(); 
    
    // 2. Sign out de Supabase
    final supabaseService = SupabaseService(); 
    await supabaseService.signOut();
      if (mounted) {
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                Navigator.pop(dialogContext);
                _handleLogout();
              },
              child: const Text("SÍ, SALIR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    if (!_profileService.isUserLoggedIn) return _buildGuestView(context);

    return ChangeNotifierProvider(
      create: (_) => GoalController()..loadExistingGoals(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<GoalController>(
          builder: (context, goalController, _) {
            if (_isLoading) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),

                  // SECCIÓN DE METAS (HU-27)
                  _buildSectionHeader(
                    title: "Mi Resumen Nutricional",
                    onAction: () => _refreshGoals(context),
                  ),
                  
                  const SizedBox(height: 10),
                  MacroChartWidget(goal: goalController.currentGoal),

                  if (goalController.currentGoal == null)
                    _buildSetupButton(() => _refreshGoals(context)),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  // OPCIONES DE CONFIGURACIÓN
                  const Text(
                    "Configuración de Cuenta",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  _buildMenuButton(
                    text: "Información Personal",
                    icon: Icons.person_outline,
                    baseColor: Colors.blueAccent,
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    text: "Preferencias de Dieta",
                    icon: Icons.flatware_outlined,
                    baseColor: Colors.orange,
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    text: "Gestionar Suscripción",
                    icon: Icons.star_outline,
                    baseColor: Colors.green,
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),
                  _buildLogoutButton(onTap: () => _showLogoutDialog(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS COMPONENTES ---

  Widget _buildProfileHeader() {
    final String email = _profileService.currentUser?.email ?? 'invitado@mail.com';
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _avatarURL != null ? NetworkImage(_avatarURL!) : null,
          child: _avatarURL == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
        ),
        const SizedBox(height: 15),
        Text(_userName ?? "Cargando...", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(email, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.blueAccent),
          onPressed: onAction,
        ),
      ],
    );
  }

  Widget _buildSetupButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF13EC5B), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.add_chart, color: Colors.black),
        label: const Text("Configurar Metas Nutricionales", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMenuButton({required String text, required IconData icon, required Color baseColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: baseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: baseColor, size: 22),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
              Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              const Text(
                "Guarda tus recetas favoritas y gestiona tu despensa personalizando tu perfil.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13EC5B),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text("Iniciar Sesión", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}