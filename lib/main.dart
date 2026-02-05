import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmpbdtwfyrzjmblfdtcb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtcGJkdHdmeXJ6am1ibGZkdGNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1NTg4NTIsImV4cCI6MjA4NTEzNDg1Mn0.2hU6k4MCdpZLo1xzEWCMCbTCHvz3R424d2EHp57Odvg',
  );

  runApp(const NutveApp());
}

class NutveApp extends StatelessWidget {
  const NutveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nutve App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.nutveDarkGreen,
        scaffoldBackgroundColor: AppColors.nutveBgGray,
      ),
      home: const SplashScreen(),
    );
  }
}