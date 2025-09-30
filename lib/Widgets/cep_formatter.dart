import 'package:flutter/services.dart';

// Iniciando a classe como Text Input Formatter (forma de utilizar em campos de texto con Input Formatters);

class CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue cepDigitado,
    TextEditingValue cepFormatado,
  ) {
    //tudo que não é numero, é descartado da string do CEP;
    var CEP = cepFormatado.text.replaceAll(RegExp(r'\D'), '');

    // o CEP deve ter 8 digitos;
    if (CEP.length > 8) {
      // Limitando que deve ter no máximo 8 digitos;
      CEP = CEP.substring(0, 8);
    }

    // variável para guardar a formatação
    String novoCEP = '';

    // Iniciando o contador, quando o caracter forgi
    for (int i = 0; i < CEP.length; i++) {
      if (i == 5) {
        novoCEP += '-';
      }
      novoCEP += CEP[i];
    }

    return TextEditingValue(
      text: novoCEP,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
