import 'dart:convert';

import 'package:teste1/models/endereco_model.dart';
import 'package:http/http.dart' as http;

class ViaCepServices {
  Future<Endereco> buscarEndereco(String cep) async {
    Uri uri = Uri.parse("https://viacep.com.br/ws/$cep/json/");

    dynamic response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Endereco.fromJson(data);
    } else {
      throw Exception("CEP não encontrado");
    }
  }
}
