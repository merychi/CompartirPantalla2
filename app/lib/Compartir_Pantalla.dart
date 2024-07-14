import 'package:compartir_pantalla/senalizacion/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class GetDisplayMediaSample extends StatefulWidget {
  final String ipClient, ipDestino;
  final dynamic offer;
  const GetDisplayMediaSample({
    super.key,
    this.offer,
    required this.ipClient,
    required this.ipDestino,
  });

  @override
  State<GetDisplayMediaSample> createState() => _GetDisplayMediaSampleState();
}

class _GetDisplayMediaSampleState extends State<GetDisplayMediaSample> {
  final socket = ClientManager.instance.socket;
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  List<RTCIceCandidate> rtcIceCadidates = [];
  RTCPeerConnection? _rtcPeerConnection;

  @override
  void initState() {
    _initRenderers();
    super.initState(); 
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _initRenderers() async {
    await _remoteRTCVideoRenderer.initialize(); 
    _setupPeerConnection();
  }

  _setupPeerConnection() async {
  _rtcPeerConnection = await createPeerConnection({
    'iceServers': [
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'}
    ]
  });

  _rtcPeerConnection!.onTrack = (event) {
    _remoteRTCVideoRenderer.srcObject = event.streams[0];
    setState(() {});
  };

  if (widget.offer != null) {
    socket!.on("IceCandidate", (data) {
      var candidate = RTCIceCandidate(
        data["iceCandidate"]["candidate"],
        data["iceCandidate"]["id"],
        data["iceCandidate"]["label"],
      );
      _rtcPeerConnection!.addCandidate(candidate);
    });

    await _rtcPeerConnection!.setRemoteDescription(
      RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
    );

    RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
    await _rtcPeerConnection!.setLocalDescription(answer);

    socket!.emit("respuestaTransmision", {
      "ipClient": widget.ipClient,
      "sdpAnswer": answer.toMap(),
    });
  } else {
    _rtcPeerConnection!.onIceCandidate = (candidate) {
      rtcIceCadidates.add(candidate);
    };

    socket!.on("transmisionRespuesta", (data) async {
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(
          data["sdpAnswer"]["sdp"],
          data["sdpAnswer"]["type"],
        ),
      );

      for (RTCIceCandidate candidate in rtcIceCadidates) {
        socket!.emit("IceCandidate", {
          "ipDestino": widget.ipDestino,
          "iceCandidate": {
            "id": candidate.sdpMid,
            "label": candidate.sdpMLineIndex,
            "candidate": candidate.candidate,
          },
        });
      }
    });

    RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
    await _rtcPeerConnection!.setLocalDescription(offer);

    socket!.emit('crearSolicitudTransmision', {
      "ipDestino": widget.ipDestino,
      "sdpOffer": offer.toMap(),
    });
  }
}


  _leaveCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remoteRTCVideoRenderer.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
