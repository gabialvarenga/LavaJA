import 'package:flutter/services.dart';

class PlacaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não é letra ou número, converte para maiúsculo
    final raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Limita a 7 caracteres (3 letras + 4 alfanum)
    final trimmed = raw.length > 7 ? raw.substring(0, 7) : raw;

    // Insere o traço após os 3 primeiros caracteres
    final formatted = trimmed.length > 3
        ? '${trimmed.substring(0, 3)}-${trimmed.substring(3)}'
        : trimmed;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
