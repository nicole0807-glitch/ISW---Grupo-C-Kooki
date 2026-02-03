import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<bool> logout() async {
    try {
      await _authService.signOut();
      return true; 
    } catch (e) {
      print(e);
      return false; 
    }
  }
}