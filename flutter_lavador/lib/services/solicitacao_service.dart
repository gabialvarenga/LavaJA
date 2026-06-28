import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/solicitacao.dart';

class SolicitacaoService {
  static Future<List<Solicitacao>> listar({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await ApiClient.get('/solicitacoes$query');
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    final lista = data['dados'] as List<dynamic>;
    return lista
        .map((j) => Solicitacao.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<Solicitacao> buscarPorId(String id) async {
    final response = await ApiClient.get('/solicitacoes/$id');
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  // Lavador aceita a solicitação — backend exige lavador_id no body
  static Future<Solicitacao> aceitar(String id) async {
    final userId = await LocalStorage.getUserId();
    final response = await ApiClient.patch('/solicitacoes/$id/status', {
      'status': 'aceita',
      'lavador_id': userId,
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  static Future<Solicitacao> recusar(String id) async {
    final response = await ApiClient.patch('/solicitacoes/$id/status', {
      'status': 'recusada',
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  static Future<Solicitacao> iniciar(String id) async {
    final response = await ApiClient.patch('/solicitacoes/$id/status', {
      'status': 'em_execucao',
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  static Future<Solicitacao> concluir(String id) async {
    final response = await ApiClient.patch('/solicitacoes/$id/status', {
      'status': 'concluida',
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  static Future<List<HistoricoStatus>> buscarHistorico(String id) async {
    final response = await ApiClient.get('/solicitacoes/$id/historico');
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    final lista = data['dados'] as List<dynamic>;
    return lista
        .map((j) => HistoricoStatus.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
