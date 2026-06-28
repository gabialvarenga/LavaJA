import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _keyUserId = 'usuario_id';
  static const _keyUserName = 'usuario_nome';
  static const _keyUserEmail = 'usuario_email';
  static const _keyUserType = 'usuario_tipo';

  static Future<void> saveUser({
    required String id,
    required String nome,
    required String email,
    required String tipo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserName, nome);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserType, tipo);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
