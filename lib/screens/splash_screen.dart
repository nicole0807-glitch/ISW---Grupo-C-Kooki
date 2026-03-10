import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import 'auth/login_screen.dart';
import 'home/main_layout.dart';
import 'nutritionist/nutritionist_main_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        if (_authController.hasSession()) {
          final homeController = context.read<HomeController>();
          await homeController.loadUserRole();

          if (mounted) {
            Widget nextScreen;
            if (homeController.isNutricionista) {
              nextScreen = const NutritionistMainScreen();
            } else {
              nextScreen = const MainLayout();
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => nextScreen),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nutveDarkGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
