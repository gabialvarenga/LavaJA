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

  static Future<Solicitacao> criar({
    required String veiculoId,
    required String endereco,
    required TipoServico tipoServico,
    String? observacoes,
  }) async {
    final userId = await LocalStorage.getUserId();
    final response = await ApiClient.post('/solicitacoes', {
      'cliente_id': userId,
      'veiculo_id': veiculoId,
      'endereco': endereco,
      'tipo_servico': tipoServico.value,
      if (observacoes != null && observacoes.isNotEmpty)
        'observacoes': observacoes,
    });
    final data = ApiClient.parseResponse(response) as Map<String, dynamic>;
    return Solicitacao.fromJson(data);
  }

  static Future<Solicitacao> cancelar(String id) async {
    final response = await ApiClient.patch(
      '/solicitacoes/$id/status',
      {'status': 'cancelada'},
    );
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
