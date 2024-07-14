import 'package:compartir_pantalla/compartir_pantalla.dart';
import 'package:compartir_pantalla/senalizacion/socket.dart';
import 'package:flutter/material.dart';

class SalaPantalla extends StatefulWidget {
  final String ip;

  const SalaPantalla({super.key, required this.ip});

  @override
  State<SalaPantalla> createState() => _SalaPantallaState();
}

class _SalaPantallaState extends State<SalaPantalla> {
  dynamic incomingSDPOffer;
  final remoteipClientTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuchar para la solicitud de transmisión
    ClientManager.instance.socket!.on("solicitarTransmision", (data) {
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  // Unirse a la transmisión
  void _joinTransmision({
  required String ipClient,
  required String ipDestino,
  dynamic offer,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GetDisplayMediaSample(
        ipClient: ipClient,
        ipDestino: ipDestino,
        offer: offer,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Merry Prueba 2p2"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Parte del cliente a ver pantalla
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: TextEditingController(
                        text: widget.ip,
                      ),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: "Tu IP de llamada:",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remoteipClientTextEditingController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "El IP del cliente remoto",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                      child: const Text(
                        "Invite",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        print("el ${widget.ip} ha solicitado la transmision de: ${remoteipClientTextEditingController.text} Proveniente de salas");
                        print("el ( $incomingSDPOffer ) es este si se ENVIA POR QUE NOA AAA");

                        _joinTransmision(
                          ipClient: widget.ip,
                          ipDestino: remoteipClientTextEditingController.text,
                        );
                      },
                    )
                  ],
                ),
              ),
            ),

            // Parte del servidor a transmitir pantalla
            if (incomingSDPOffer != null)
              Positioned(
                top: 100, // Ajusta la posición según sea necesario
                left: 20, // Ajusta la posición según sea necesario
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(
                      "Incoming Call from ${incomingSDPOffer["ipClient"]}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.call_end),
                          color: Color.fromARGB(175, 89, 145, 141),
                          onPressed: () {
                            setState(() => incomingSDPOffer = null);
                        },
                      ),
                        IconButton(
                          icon: const Icon(Icons.call),
                          color: Colors.greenAccent,
                          onPressed: () {
                            _joinTransmision(
                              ipClient: incomingSDPOffer["ipClient"]!,
                              ipDestino: widget.ip,
                              offer: incomingSDPOffer["sdpOffer"],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}
