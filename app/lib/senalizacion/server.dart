import 'package:socket_io/socket_io.dart';
import 'package:flutter/material.dart';

class ServerManager with ChangeNotifier {
  Server? _server;
  Map<String, String> _connectedClients =
      {}; // Changed to Map<String, String> for client IDs
  Map<String, String> get connectedClients => _connectedClients;

  void startServer() {
    _server = Server();

    _server?.on('connection', (client) {
      try {
        // Forma correcta de obtener la IP desde el handshake
        var handshake = client.handshake;
        String ip = handshake['query']['ip'] ?? '';
        String ipSala = handshake['query']['serverIp'] ?? '';

        _connectedClients[client.id] = ip;
        notifyListeners();
        print('Cliente conectado: ${client.id}');
        client.join(ipSala);

        client.on("crearSolicitudTransmision", (data) {
          var ipDestino = data['ipDestino'];
          var sdpOffer = data['sdpOffer'];
          print("Server: El $sdpOffer es: ");
          print('Server: Solicitud de transmisión creada por $ip para $ipDestino');

          _server?.to(ipDestino).emit("solicitarTransmision", {
            "clientIp": ip,
            "sdpOffer": sdpOffer,
          });
          print ("server: valor del $sdpOffer");
        });

        client.on("respuestaTransmision", (data) {
          var clientIp = data['clientIp'];
          var sdpAnswer = data['sdpAnswer'];
          print('Respuesta de transmisión de $ip para $clientIp');

          _server?.to(clientIp).emit("transmisionRespuesta", {
            "clientDestino": ip,
            "sdpAnswer": sdpAnswer,
          });
        });

        client.on("IceCandidate", (data) {
          var ipDestino = data['ipDestino'];
          var iceCandidate = data['iceCandidate'];
          print('Candidato ICE de $ip para $ipDestino');

          _server?.to(ipDestino).emit("IceCandidate", {
            "sender": ip,
            "iceCandidate": iceCandidate,
          });
        });

        client.on('disconnect', (_) {
          _connectedClients.remove(client.id); // Fixed client removal
          notifyListeners();
          print('Cliente desconectado: ${client.id}');
        });
      } catch (e) {
        print('Error en la conexión del cliente: ${client.id}, Error: $e');
      }
    });

    try {
      _server?.listen(3000);
      print('Servidor escuchando en el puerto 3000');
    } catch (e) {
      print('Error al iniciar el servidor: $e');
    }
  }

  @override
  void dispose() {
    _server?.close();
    print('Servidor cerrado');
    super.dispose();
  }
}
