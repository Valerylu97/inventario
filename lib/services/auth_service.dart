import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserRole = 'user_role'; // 'ADMIN' o 'OPERADOR'
  static const String keyUserName = 'user_name';

  // Iniciar Sesión
  static Future<void> login(String role, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, true);
    await prefs.setString(keyUserRole, role);
    await prefs.setString(keyUserName, username);
  }

  // Cerrar Sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserName);
  }

  // Obtener Rol Actual
  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserRole) ?? 'OPERADOR';
  }

  // Verificar si hay sesión activa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }
}