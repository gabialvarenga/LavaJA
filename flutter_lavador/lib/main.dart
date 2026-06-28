import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/websocket_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WebSocketService(),
      child: const LavaJaLavadorApp(),
    ),
  );
}
