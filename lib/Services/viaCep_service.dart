import 'dart:convert';
import 'package:atividade_cep_cache/Models/endereco_model.dart';
import 'package:atividade_cep_cache/Services/cache_service.dart';
import 'package:atividade_cep_cache/Services/connectivity_service.dart';
import 'package:http/http.dart' as http;

class ViaCepServices {
  // Instanciando as classes dos serviços

  final ConnectivityService connectivityService = ConnectivityService();
  final CacheService cacheService = CacheService();

  // Iniciando a conecção
  ViaCepServices() {
    connectivityService.initialize();
  }

  //Função para buscar o CEP

  Future<Endereco> buscarCep(String cep, dynamic context) async {
    // checando formatação do que foi digitiado;
    cep = cep.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      throw Exception("CEP inválido. Deve conter 8 dígitos.");
    }

    // booleano para receber resultado de checagem da conexão
    bool temInternet = await connectivityService.checkInitialConnectivity(
      context,
    );

    if (temInternet) {
      print("Buscando na API...");
      try {
        Uri uri = Uri.parse("https://viacep.com.br/ws/$cep/json/");
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final endereco = Endereco.fromJson(data);

          await CacheService.salvarEndereco(endereco);
          print("Encontrado na API e salvo no cache");
          return endereco;
        } else {
          print("API retornou erro, tentando buscar no cache...");
          return await _buscarNoCache(cep);
        }
      } catch (e) {
        print("Erro na API: $e, tentando buscar no cache...");
        return await _buscarNoCache(cep);
      }
    } else {
      print("Sem internet, buscando no cache...");
      return await _buscarNoCache(cep);
    }
  }

  Future<Endereco> _buscarNoCache(String cep) async {
    final jsonString = await CacheService.listarCepsConsultados(
      'endereco_salvo',
    );
    if (jsonString != null) {
      print("Encontrado no cache");
      return Endereco.fromJson(jsonDecode(jsonString));
    } else {
      throw Exception("CEP não encontrado no cache e sem conexão.");
    }
  }

  Future<Endereco?> obterHistorico() async {
    final jsonString = await CacheService.listarCepsConsultados(
      'endereco_salvo',
    );
    if (jsonString != null) {
      return Endereco.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  // 2.5 - Limpar histórico
  Future<void> limparHistorico() async {
    await CacheService.limparCache();
    print("Cache de endereços limpo");
  }
}
