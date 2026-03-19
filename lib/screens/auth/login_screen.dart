import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../utils/app_colors.dart';
import '../home/main_layout.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Animation Controller for entrance
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Animation for background gradient
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();

    // Background animation
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _bgAnimController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showKookiSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade400
            : AppColors.nutveSelectionGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        elevation: 10,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showKookiSnackBar(
        'Por favor ingresa tu usuario y contraseña',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authController.login(
        username: username,
        password: password,
      );

      if (success && mounted) {
        await context.read<HomeController>().loadUserRole();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainLayout(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else if (mounted) {
        _showKookiSnackBar('Usuario o contraseña incorrectos', isError: true);
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        String displayMsg = 'Error al iniciar sesión. Intenta de nuevo.';

        if (errorStr.contains('invalid login credentials') ||
            errorStr.contains('not found')) {
          displayMsg = 'Usuario o contraseña no válidos.';
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          displayMsg = 'Problema de conexión. Revisa tu internet.';
        }

        _showKookiSnackBar(displayMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.nutveBgGray;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Contenido Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo (Fuera de la tarjeta)
                        Hero(
                          tag: 'logo',
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
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
                        const SizedBox(height: 25),
                        Text(
                          "KOOKI",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.nutveSelectionGreen
                                : AppColors.nutveDarkGreen,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bienvenido de nuevo.",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Tarjeta de Formulario (Sólida)
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildPremiumField(
                                "Usuario",
                                Icons.person_outline,
                                _usernameController,
                                isDark,
                              ),
                              const SizedBox(height: 20),
                              _buildPremiumField(
                                "Contraseña",
                                Icons.lock_outline,
                                _passwordController,
                                isDark,
                                isPass: true,
                              ),
                              const SizedBox(height: 35),
                              _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.nutveSelectionGreen,
                                    )
                                  : _buildLoginButton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 35),

                        // Link de Registro
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: "¿No tienes cuenta? ",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black45,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Crear perfil",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.nutveDarkGreen,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Botón para volver (Estilo Receta)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumField(
    String label,
    IconData icon,
    TextEditingController? controller,
    bool isDark, {
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? _obscurePassword : false,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isDark ? AppColors.nutveSelectionGreen : AppColors.nutveDarkGreen,
          ),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.nutveSelectionGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.nutveSelectionGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _login,
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
}
