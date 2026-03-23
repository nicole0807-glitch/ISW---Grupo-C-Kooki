import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import 'auth/welcome_screen.dart';
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
    _checkInitialRedirection();
  }

  Future<void> _checkInitialRedirection() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      if (_authController.hasSession()) {
        try {
          final homeController = context.read<HomeController>();
          await homeController
              .loadUserRole()
              .timeout(const Duration(seconds: 15));

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
        } catch (e) {
          debugPrint("⚠️ Timeout or error in splash redirection: $e");
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          }
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
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
