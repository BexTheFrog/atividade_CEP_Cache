import 'dart:convert';
import 'package:atividade_cep_cache/Models/endereco_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final _cache = SharedPreferences.getInstance();
  static const _endereco = 'endereco_salvo';

  // Salvar endereço
  static Future<void> salvarEndereco(Endereco endereco) async {
    final prefs = await _cache;
    final enderecoJson = jsonEncode(endereco.toJson());
    await prefs.setString(_endereco, enderecoJson);
  }

  // Listar CEP consultados
  static Future<String?> listarCepsConsultados(String chave) async {
    final prefs = await _cache;
    return prefs.getString(chave);
  }

  // Limpar cache
  static Future<void> limparCache() async {
    final prefs = await _cache;
    await prefs.remove(_endereco);
  }
}
