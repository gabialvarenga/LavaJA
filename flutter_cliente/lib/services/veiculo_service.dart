import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/veiculo.dart';

class VeiculoService {
  static Future<List<Veiculo>> listar() async {
    final userId = await LocalStorage.getUserId();
    final response = await ApiClient.get('/veiculos?usuario_id=$userId');
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    final lista = data['dados'] as List<dynamic>;
    return lista
        .map((j) => Veiculo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Veiculo> criar({
    required String placa,
    required String modelo,
    required String cor,
  }) async {
    final userId = await LocalStorage.getUserId();
    final response = await ApiClient.post('/veiculos', {
      'usuario_id': userId,
      'placa': placa,
      'modelo': modelo,
      'cor': cor,
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Veiculo.fromJson(data);
  }
}
