import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:atividade_cep_cache/Models/endereco_model.dart';
import 'package:atividade_cep_cache/Services/connectivity_service.dart';
import 'package:atividade_cep_cache/Services/viaCep_service.dart';
import 'package:atividade_cep_cache/Services/cache_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Variáveis de estado
  bool _temInternet = false;
  bool _buscando = false;
  Endereco? _enderecoEncontrado;
  String? _mensagemErro;
  List<String> _historico = [];

  // Serviços e controlador
  final ConnectivityService _connectivityService = ConnectivityService();
  final ViaCepServices _cepService = ViaCepServices();
  final TextEditingController _cepController = TextEditingController();
  late StreamSubscription<bool> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
    _checkInitialConnection();

    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      status,
    ) {
      setState(() {
        _temInternet = status;
      });
    });

    _carregarHistorico();
  }

  Future<void> _checkInitialConnection() async {
    bool status = await _connectivityService.checkInitialConnectivity(context);
    setState(() {
      _temInternet = status;
    });
  }

  Future<void> _carregarHistorico() async {
    // Buscar histórico do cache
    String? cepSalvo = await CacheService.listarCepsConsultados(
      'endereco_salvo',
    );

    setState(() {
      _historico = cepSalvo != null ? [cepSalvo] : [];
    });
  }

  Future<void> _buscarCep({String? cep}) async {
    setState(() {
      _mensagemErro = null;
      _enderecoEncontrado = null;
      _buscando = true;
    });

    final cepParaBuscar = cep ?? _cepController.text;

    try {
      Endereco endereco = await _cepService.buscarCep(cepParaBuscar, context);

      setState(() {
        _enderecoEncontrado = endereco;
        if (endereco.cep != null && !_historico.contains(endereco.cep)) {
          _historico.add(endereco.cep!);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _temInternet
                ? "Endereço encontrado na internet ✅"
                : "Endereço encontrado no cache ⚠️",
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _mensagemErro = e.toString();
      });
    } finally {
      setState(() {
        _buscando = false;
      });
    }
  }

  Future<void> _limparHistorico() async {
    // Aqui limpa o cache também se quiser
    setState(() {
      _historico.clear();
      _enderecoEncontrado = null;
      _cepController.clear();
    });
  }

  @override
  void dispose() {
    _cepController.dispose();
    _connectivitySubscription.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
            Spacer(),
            Icon(
              _temInternet ? Icons.wifi_2_bar_rounded : Icons.wifi_off_rounded,
              color: _temInternet ? Colors.green : Colors.red,
            ),
            SizedBox(width: 8),
            Text(_temInternet ? "Online" : "Offline"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_temInternet)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                color: Colors.orange.shade200,
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Você está offline. Apenas CEPs já consultados podem ser buscados.",
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _cepController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: "Digite o CEP",
                prefixIcon: !_temInternet ? Icon(Icons.save) : null,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _buscando ? null : _buscarCep,
              icon: _buscando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.search),
              label: Text(_buscando ? "Buscando..." : "Buscar CEP"),
            ),
            SizedBox(height: 12),
            if (_mensagemErro != null)
              Container(
                padding: EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(Icons.error),
                    SizedBox(width: 8),
                    Expanded(child: Text(_mensagemErro!)),
                  ],
                ),
              ),
            if (_enderecoEncontrado != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Endereço Encontrado",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _temInternet
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _temInternet ? "Online" : "Cache",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("CEP: ${_enderecoEncontrado!.cep ?? '-'}"),
                      Text(
                        "Logradouro: ${_enderecoEncontrado!.logradouro ?? '-'}",
                      ),
                      Text("Bairro: ${_enderecoEncontrado!.bairro ?? '-'}"),
                      Text("Cidade: ${_enderecoEncontrado!.localidade ?? '-'}"),
                      Text("Estado: ${_enderecoEncontrado!.uf ?? '-'}"),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 12),
            if (_historico.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Histórico de Consultas",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: _limparHistorico,
                        child: Text("Limpar"),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: _historico
                        .map(
                          (cep) => ActionChip(
                            label: Text(cep),
                            onPressed: () {
                              _cepController.text = cep;
                              _buscarCep(cep: cep);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
