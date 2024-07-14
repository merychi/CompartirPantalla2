import 'package:socket_io_client/socket_io_client.dart' as IO;

class ClientManager {
  IO.Socket? socket;

  ClientManager._();
  static final instance = ClientManager._();

  void connectToServer(String serverIp, ip) {
  socket = IO.io('http://$serverIp:3000', <String, dynamic>{
    'transports': ['websocket'],
    'query': {'ip': ip, 'ipSala': serverIp}
  });

  socket?.on('connect', (_) {
    print('Connected to server');
  });

  socket?.on('solicitarTransmision', (data) {
    // Handle incoming transmission request
    print('Incoming transmission request from ${data['clientIp']}');
    // Process the SDP offer and respond
  });

  socket?.on('transmisionRespuesta', (data) {
    // Handle transmission response
    print('Transmission response from ${data['clientDestino']}');
    // Process the SDP answer
  });

  socket?.on('IceCandidate', (data) {
    // Handle incoming ICE candidate
    print('ICE Candidate from ${data['sender']}');
    // Add the ICE candidate to the peer connection
  });

  socket?.on('disconnect', (_) {
    print('Disconnected from server');
  });
}

}
