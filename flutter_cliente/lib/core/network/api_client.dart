import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/local_storage.dart';

class ApiClient {
  // Dispositivo físico via USB: rode "adb reverse tcp:3000 tcp:3000" e use localhost
  // Emulador Android: troque para http://10.0.2.2:3000/api
  // WiFi (sem USB): troque pelo IP da máquina, ex: http://192.168.102.152:3000/api
  static const String _baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, String>> _headers() async {
    final userId = await LocalStorage.getUserId();
    return {
      'Content-Type': 'application/json',
      if (userId != null) 'x-usuario-id': userId,
    };
  }

  static const _timeout = Duration(seconds: 10);

  static Future<http.Response> get(String path) async {
    return http
        .get(Uri.parse('$_baseUrl$path'), headers: await _headers())
        .timeout(_timeout,
            onTimeout: () =>
                throw Exception('Servidor não respondeu. Verifique sua conexão.'));
  }

  static Future<http.Response> post(
      String path, Map<String, dynamic> body) async {
    return http
        .post(Uri.parse('$_baseUrl$path'),
            headers: await _headers(), body: jsonEncode(body))
        .timeout(_timeout,
            onTimeout: () =>
                throw Exception('Servidor não respondeu. Verifique sua conexão.'));
  }

  static Future<http.Response> patch(
      String path, Map<String, dynamic> body) async {
    return http
        .patch(Uri.parse('$_baseUrl$path'),
            headers: await _headers(), body: jsonEncode(body))
        .timeout(_timeout,
            onTimeout: () =>
                throw Exception('Servidor não respondeu. Verifique sua conexão.'));
  }

  static dynamic parseResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final msg = (data is Map)
          ? (data['erro'] ?? data['message'] ?? 'Erro ${response.statusCode}')
          : 'Erro ${response.statusCode}';
      throw Exception(msg);
    }
    return data;
  }
}
