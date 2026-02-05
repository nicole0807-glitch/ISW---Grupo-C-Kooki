import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../main.dart'; 
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
 
}

class _ProfileScreenState extends State<ProfileScreen> {
  final bool _isLoading = false;

   void _showLogoutDialog(BuildContext context) {
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
                Navigator.pop(context);
                
                await authController.logout();
                
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) =>  LoginScreen()),
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
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
            ),
      ),
    );
  }
}