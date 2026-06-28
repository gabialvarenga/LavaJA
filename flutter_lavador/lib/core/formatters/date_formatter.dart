class DateFormatter {
  static String horaLocal(String timestamp) {
    final local = _paraLocal(timestamp);
    if (local == null) return '';
    return '${_dois(local.hour)}:${_dois(local.minute)}';
  }

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
    final utc = DateTime.utc(
        dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return utc.toLocal();
  }

  static String _dois(int n) => n.toString().padLeft(2, '0');
}
