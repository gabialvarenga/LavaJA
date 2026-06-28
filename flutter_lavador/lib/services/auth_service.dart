import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/usuario.dart';

class AuthService {
  static Future<Usuario> registrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final response = await ApiClient.post('/usuarios', {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'tipo': 'lavador',
      'senha': senha,
    });

    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    final usuario = Usuario.fromJson(data);

    await LocalStorage.saveUser(
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      tipo: usuario.tipo,
    );

    return usuario;
  }

  static Future<String?> getStoredUserId() => LocalStorage.getUserId();
  static Future<String?> getStoredUserName() => LocalStorage.getUserName();
  static Future<String?> getStoredUserEmail() => LocalStorage.getUserEmail();
  static Future<void> logout() => LocalStorage.clear();
}
