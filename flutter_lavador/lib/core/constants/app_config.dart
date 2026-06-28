///   PARA TROCAR O SERVIDOR, altere APENAS [host] abaixo:
///   • Dispositivo físico via USB: rode "adb reverse tcp:3000 tcp:3000" e use 'localhost'
///   • Emulador Android: '10.0.2.2'
///   • WiFi (sem USB): IP da máquina, ex: '192.168.0.10'
class AppConfig {
  static const String host = 'localhost';
  static const int port = 3000;

  static String get baseUrl => 'http://$host:$port/api';
  static String get wsUrl => 'ws://$host:$port';
}
