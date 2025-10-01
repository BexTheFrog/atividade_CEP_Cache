import 'package:atividade_cep_cache/Services/connectivity_service.dart';
import 'package:atividade_cep_cache/Services/viaCep_service.dart';
import 'package:flutter/material.dart';

class TabelaConsultaCep extends StatefulWidget {
  const TabelaConsultaCep({super.key});

  @override
  State<TabelaConsultaCep> createState() => _TabelaConsultaCepState();
}

class _TabelaConsultaCepState extends State<TabelaConsultaCep> {
  bool _temInternet = true; // Verifica conexão com a internet
  bool _buscando = false; // Indica se está buscando o CEP
  Endereco? _enderecoEncontrado; // Endereço buscado 
  String? _mensagemErro; // Mensagem de erro
  final List<String> _historico = []; // Histórico de endereços

  late final ConnectivityService _connectivityService; // Serviço de conexão
  late final ViaCepServices _viaCepServices; // API ViaCEP
  final TextEditingController _cepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _viaCepServices = ViaCepServices();

    // Monitorando status de conexão
    _connectivityService.statusStream.listen((online) {
      setState(() => _temInternet = online);
    });
  }

  Future<void> _buscarCep() async {
    setState(() {
      _mensagemErro = null;
      _enderecoEncontrado = null;
      _buscando = true;
    });

    try {
      final cep = _cepController.text; 
      final endereco = await _viaCepServices.buscarCep(cep, online: _temInternet);

      setState(() {
        _enderecoEncontrado = endereco;
        if (!_historico.contains(cep)) {
          _historico.add(cep);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _temInternet
                ? 'Endereço encontrado! Você está conectado à internet.'
                : 'Endereço carregado do cache.',
          ),
        ),
      );
    } catch (erro) {
      setState(() => _mensagemErro = erro.toString());
    } finally {
      setState(() => _buscando = false);
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de CEP'),
        actions: [
          Row(
            children: [
              Icon(
                _temInternet ? Icons.wifi : Icons.wifi_off,
                color: _temInternet ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(_temInternet ? 'Online' : 'Offline'),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_temInternet)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.purple,
                child: Row(
                  children: const [
                    Icon(Icons.info_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sem conexão com a internet. Somente endereços salvos podem ser consultados.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: _cepController,
              decoration: InputDecoration(
                labelText: 'Informe o CEP',
                suffixIcon: !_temInternet
                    ? const Icon(Icons.cached, color: Colors.red)
                    : null,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _buscando ? null : _buscarCep,
              icon: _buscando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_buscando ? 'Buscando...' : 'Buscar CEP'),
            ),
            const SizedBox(height: 12),

            if (_mensagemErro != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mensagemErro!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            if (_enderecoEncontrado != null)
              Card(
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Endereço Encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              _temInternet ? "Internet" : "Cache",
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                _temInternet ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('CEP: ${_enderecoEncontrado!.cep}'),
                      Text('Logradouro: ${_enderecoEncontrado!.logradouro}'),
                      Text('Bairro: ${_enderecoEncontrado!.bairro}'),
                      Text('Cidade: ${_enderecoEncontrado!.cidade}'),
                      Text('Estado: ${_enderecoEncontrado!.estado}'),
                    ],
                  ),
                ),
              ),

            if (_historico.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Histórico de Consultas",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(_historico.clear),
                    child: const Text("Limpar"),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _historico.map((cep) {
                  return ActionChip(
                    label: Text(cep),
                    onPressed: () {
                      _cepController.text = cep;
                      _buscarCep();
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
