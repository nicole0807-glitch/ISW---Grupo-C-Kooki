import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectamos si el modo oscuro está activo
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Cambiamos el fondo según el modo
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.nutveBgGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
              
              // 1. Image (Logo)
              Hero(
                tag: 'logo',
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 2. Text ("Welcome")
              Text(
                "BIENVENIDO A KOOKI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.nutveSelectionGreen : AppColors.nutveDarkGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 15),
              
              // 3. Text ("Subtitle")
              Text(
                "Tu asistente personal para una cocina inteligente y sin desperdicios.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const Spacer(),
              
              // 4. Button ("Iniciar sesión")
              _buildLoginButton(context),
              
              const SizedBox(height: 20),
              
              // 5. Button ("Continuar como Invitado")
              _buildGuestButton(context, isDark),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.nutveSelectionGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.nutveSelectionGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        child: const Text(
          "INICIAR SESIÓN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? Colors.white24 : AppColors.nutveDarkGreen, 
            width: 1.5
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        },
        child: Text(
          "CONTINUAR COMO INVITADO",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.nutveDarkGreen,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
