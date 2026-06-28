import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/app_config.dart';
import '../core/storage/local_storage.dart';

class WsEvent {
  final String evento;
  final Map<String, dynamic> dados;

  const WsEvent({required this.evento, required this.dados});

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
        evento: json['evento'] as String,
        dados: (json['dados'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  WsEvent? _ultimoEvento;
  bool _conectado = false;

  WsEvent? get ultimoEvento => _ultimoEvento;
  bool get conectado => _conectado;

  Future<void> conectar() async {
    final userId = await LocalStorage.getUserId();
    if (userId == null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));

      // Registra como lavador — backend vai rotear solicitacao.criada para este client
      _channel!.sink.add(jsonEncode({
        'tipo': 'lavador',
        'usuario_id': userId,
      }));

      _conectado = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          try {
            final json =
                jsonDecode(message as String) as Map<String, dynamic>;
            if (json.containsKey('evento')) {
              _ultimoEvento = WsEvent.fromJson(json);
              notifyListeners();
            }
          } catch (_) {}
        },
        onDone: () {
          _conectado = false;
          notifyListeners();
        },
        onError: (_) {
          _conectado = false;
          notifyListeners();
        },
      );
    } catch (_) {
      _conectado = false;
    }
  }

  void desconectar() {
    _channel?.sink.close();
    _channel = null;
    _conectado = false;
  }

  @override
  void dispose() {
    desconectar();
    super.dispose();
  }
}
