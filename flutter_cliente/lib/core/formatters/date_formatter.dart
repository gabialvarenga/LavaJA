/// Converte timestamps do backend para o fuso horário local.
///
/// O backend grava em UTC (SQLite `datetime('now')`), no formato
/// 'YYYY-MM-DD HH:MM:SS'. Aqui interpretamos como UTC e convertemos
/// para a hora local do dispositivo.
class DateFormatter {
  /// Retorna 'HH:MM' na hora local. Vazio se não conseguir parsear.
  static String horaLocal(String timestamp) {
    final local = _paraLocal(timestamp);
    if (local == null) return '';
    return '${_dois(local.hour)}:${_dois(local.minute)}';
  }

  /// Retorna 'DD/MM HH:MM' na hora local. Vazio se não conseguir parsear.
  static String dataHoraLocal(String timestamp) {
    final local = _paraLocal(timestamp);
    if (local == null) return '';
    return '${_dois(local.day)}/${_dois(local.month)} '
        '${_dois(local.hour)}:${_dois(local.minute)}';
  }

  static DateTime? _paraLocal(String ts) {
    final normalizado = ts.contains('T') ? ts : ts.replaceFirst(' ', 'T');
    final dt = DateTime.tryParse(normalizado);
    if (dt == null) return null;
    // DateTime.parse trata string sem 'Z' como local; forçamos UTC e convertemos.
    final utc = DateTime.utc(
        dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return utc.toLocal();
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');
}
