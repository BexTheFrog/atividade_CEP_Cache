import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  //Intanciamento da importanção do serviço connectivity, ela é final pois não será alterada novamente;
  final Connectivity _connectivity = Connectivity();

  StreamController<bool>? _connectivityController;

  //função para iniciar o serviço;

  void initialize() {
    // Inicilizia o controller, o broadcast mantém a escuta dentro do aplicativo sem necessitar reiniciar o controller
    _connectivityController = StreamController.broadcast();
  }

  // O metodo para checar inicialmente a conexão, ela é uma future async, pois precisamos esperar a connectivity
  Future<bool> checkInitialConnectivity(BuildContext context) async {
    // Estamos denominando uma variavel tipo lista de resultador de conexão;
    List<ConnectivityResult> listConnectivity = await _connectivity
        .checkConnectivity();

    return verifyStatusConnectivity(listConnectivity, context);
  }

  // Função para verificar as resultados da conexão (vem como uma lista, então o parâmetro é uma lista)
  Future<bool> verifyStatusConnectivity(
    List<ConnectivityResult> list,
    BuildContext context,
  ) async {
    if (list.contains(ConnectivityResult.none) && list.length == 1) {
      _connectivityController?.add(false);

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text("Não há conecção com a internet"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          );
        },
      );

      return false;
    }

    //print("Conectado");

    for (ConnectivityResult result in list) {
      if (result == ConnectivityResult.wifi) {
        //print("Tá no Wi-Fi");
      }

      if (result == ConnectivityResult.mobile) {
        //print("Tá no mobile");
      }
    }

    _connectivityController?.add(true);
    return true;
  }

  // Diferente forma de criar métodos
  Stream<bool> get connectivityStream {
    if (_connectivityController == null) {
      initialize();
    }
    return _connectivityController!.stream;
  }

  void dispose() {
    _connectivityController?.close();
  }
}
