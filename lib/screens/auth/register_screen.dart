import 'dart:io';
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

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final AuthController _authController = AuthController();
  
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _signUp() async {
    final String email = _emailController.text.trim();
    final String password = _passController.text.trim();
    
    if (email.isEmpty || password.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      List<String> nameParts = _nameController.text.trim().split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      String username = _userController.text.trim();

      bool success = await _authController.registerUser(
        email: email,
        password: password,
        firstName: firstName, 
        lastName: lastName,
        username: username,
        imageFile: _imageFile,
      );

      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GoalSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nutveDarkGreen,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text("CREAR PERFIL", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white10,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildInput("Nombre y Apellido", Icons.badge, _nameController),
            _buildInput("Username (Único)", Icons.alternate_email, _userController),
            _buildInput("Email (Único)", Icons.email, _emailController),
            _buildInput("Contraseña", Icons.lock, _passController, isPass: true),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.nutveDarkGreen,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _signUp,
                    child: const Text("REGISTRAR CUENTA"),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
      ),
    );
  }
}