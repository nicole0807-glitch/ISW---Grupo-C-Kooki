import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 100, color: AppColors.nutveSelectionGreen),
            const SizedBox(height: 20),
            const Text("¡Todo listo!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.nutveDarkGreen)),
            const Text("Tu perfil ha sido configurado."),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.nutveDarkGreen, foregroundColor: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout())),
              child: const Text("IR AL HOME"),
            ),
          ],
        ),
      ),
    );
  }
}