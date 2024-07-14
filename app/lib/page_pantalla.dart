import 'package:compartir_pantalla/Compartir_Pantalla.dart';
import 'package:compartir_pantalla/salas.dart';
import 'package:compartir_pantalla/senalizacion/server.dart';
import 'package:compartir_pantalla/senalizacion/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:socket_io/socket_io.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required String title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _serverIpController = TextEditingController();
  bool isServer = false;
  String localIp = '', ipAddress = '', ipServidor = '';

  @override
  void initState() {
    super.initState();
    _getLocalIp();
  }

  // Obtenemos IP de los celulares que abren la aplicación
  Future<void> _getLocalIp() async {
    final info = NetworkInfo();
    String? ip = await info.getWifiIP();
    setState(() {
      localIp = ip ?? 'Unable to get IP';
    });
  }

  bool isValidIp(String ip) {
    final regex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return regex.hasMatch(ip);
  }

  //Primer interfaz que permite seleccionar al celular si desea ser servidor o cliente
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MerryPruebaSocket"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {},
            ),
          ),
          Text('Local IP: $localIp'),
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Ingrese su IP para compartir su pantalla:',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              ipAddress = _ipController.text;

              //Iniciamos un servidor en dado caso de que el usuario desee compartir su pantalla
              //El servidor estará hospedado en el celular del usuario y se creará la sala correspondiente.
              if (ipAddress.isNotEmpty && isValidIp(ipAddress) && ipAddress == localIp) {
                context.read<ServerManager>().startServer();
                ClientManager.instance.connectToServer(ipAddress, localIp);
                setState(() {
                  isServer = true;
                });
              } 
            },
            child: Text('Permitir'),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _serverIpController,
            decoration: InputDecoration(
              labelText: 'Ingrese la IP del servidor para conectarse:',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              ipServidor = _serverIpController.text;

              // Nos conectamos al servidor ingresado por el usuario
              if (ipServidor.isNotEmpty && isValidIp(ipServidor)) {
                ClientManager.instance.connectToServer(ipServidor, localIp);
                setState(() {
                  isServer = false;
                });
              }
            },
            child: Text('Conectar'),
          ),
          SizedBox(height: 20),
          Text('Usuarios Activos:'),
          Expanded(
            child: Consumer<ServerManager>(
              builder: (context, serverManager, child) {
                return ListView.builder(
                  itemCount: serverManager.connectedClients.length,
                  itemBuilder: (context, index) {
                    final socket =
                        serverManager.connectedClients.keys.elementAt(index);
                    final ip = serverManager.connectedClients[socket];
                    return ListTile(
                      title: Text(' Sockek: $socket - IP: $ip'),
                    );
                  },
                );
              },
            ),
          ),
          ListTile(
            title: Text('observarPantalla'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext) => SalaPantalla(ip: localIp)));
            },
          ),
          ElevatedButton(
            child: const Text("Foreground Mode"),
            onPressed: () =>
                FlutterBackgroundService().invoke("setAsForeground"),
          ),

          /*ElevatedButton(
              child: Text(text),
              onPressed: () async {
                final service = FlutterBackgroundService();
                var isRunning = await service.isRunning();
                isRunning
                    ? service.invoke("stopService")
                    : service.startService();

                setState(() {
                  text = isRunning ? 'Start Service' : 'Stop Service';
                });
              },
            ),*/
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _serverIpController.dispose();
    super.dispose();
  }
}
