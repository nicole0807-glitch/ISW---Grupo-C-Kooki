import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../onboarding/goal_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final AuthController _authController = AuthController();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _obscurePass = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  void _showAuthSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
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
        margin: const EdgeInsets.all(18),
        duration: const Duration(seconds: 4),
        elevation: 12,
      ),
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final name = _nameController.text.trim();
    final username = _userController.text.trim();

    if (name.isEmpty) {
      _showAuthSnackBar('Por favor ingresa tu nombre completo.');
      return;
    }
    if (username.isEmpty) {
      _showAuthSnackBar('El nombre de usuario no puede estar vacío.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showAuthSnackBar('Ingresa un correo electrónico válido.');
      return;
    }
    if (password.length < 6) {
      _showAuthSnackBar('La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final success = await _authController.registerUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        username: username,
        imageBytes: _imageBytes,
      );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GoalSelectionScreen()),
          (route) => false,
        );
      } else if (mounted) {
        _showAuthSnackBar(
          'No fue posible completar el registro. Intenta de nuevo.',
        );
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString().toLowerCase();
        String msg;
        if (raw.contains('already registered') ||
            raw.contains('duplicate') ||
            raw.contains('already exists')) {
          msg = 'Este correo ya está registrado. Prueba iniciar sesión.';
        } else if (raw.contains('password') ||
            raw.contains('contraseña') ||
            raw.contains('weak')) {
          msg =
              'Contraseña no válida. Usa al menos 6 caracteres con letras y números.';
        } else if (raw.contains('invalid email') || raw.contains('correo')) {
          msg = 'El correo ingresado no tiene un formato válido.';
        } else {
          msg = 'Ocurrió un error al crear la cuenta. Intenta de nuevo.';
        }
        _showAuthSnackBar(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo / Icon (Fuera de la tarjeta)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.nutveSelectionGreen.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.nutveSelectionGreen.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.nutveSelectionGreen,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Crea tu cuenta",
                      style: TextStyle(
                        color: isDark
                            ? AppColors.nutveSelectionGreen
                            : AppColors.nutveDarkGreen,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (isDark) // Adjustment for dark mode visibility
                      const Text(
                        "Únete a la comunidad Kooki",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      )
                    else
                      Text(
                        "Únete a la comunidad Kooki",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.65),
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 35),

                    // Avatar picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.nutveSelectionGreen,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.nutveSelectionGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: isDark ? Colors.white10 : Colors.white,
                              backgroundImage: _imageBytes != null
                                  ? MemoryImage(_imageBytes!)
                                  : null,
                              child: _imageBytes == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 55,
                                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.nutveSelectionGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Toca para elegir foto",
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Form card (Sólida)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
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
                          _buildField(
                            "Nombre completo",
                            Icons.badge_rounded,
                            _nameController,
                            isDark,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            "Usuario único",
                            Icons.alternate_email_rounded,
                            _userController,
                            isDark,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            "Correo electrónico",
                            Icons.email_rounded,
                            _emailController,
                            isDark,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            "Contraseña",
                            Icons.lock_rounded,
                            _passController,
                            isDark,
                            isPass: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Submit button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                color: AppColors.nutveSelectionGreen,
                                strokeWidth: 3,
                              ),
                            )
                          : GestureDetector(
                              onTap: _signUp,
                              child: Container(
                                width: double.infinity,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: AppColors.nutveSelectionGreen,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.nutveSelectionGreen.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    "CREAR CUENTA",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Ya tienes cuenta? ",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black45,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.nutveDarkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // Botón para volver (Estilo Receta)
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

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller,
    bool isDark, {
    bool isPass = false,
    TextInputType? keyboardType,
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
        obscureText: isPass && _obscurePass,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.nutveSelectionGreen,
            size: 20,
          ),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark ? Colors.white38 : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
