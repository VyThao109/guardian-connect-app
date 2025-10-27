import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

enum CameraConnectionStatus {
  disconnected,
  initialized,
  connecting,
  connected,
  failed,
}

class CameraService {
  RTCVideoRenderer? _remoteRenderer;
  RTCPeerConnection? _peerConnection;

  final String raspUrl = 'http://192.168.1.54:8000/offer';

  // Stream để notify status changes
  final _statusController =
      StreamController<CameraConnectionStatus>.broadcast();
  Stream<CameraConnectionStatus> get statusStream => _statusController.stream;

  CameraConnectionStatus _currentStatus = CameraConnectionStatus.disconnected;
  CameraConnectionStatus get currentStatus => _currentStatus;

  Future<void> initialize(RTCVideoRenderer renderer) async {
    _remoteRenderer = renderer;
    await _remoteRenderer?.initialize();
    _updateStatus(CameraConnectionStatus.initialized);
  }

  Future<bool> connect() async {
    if (_remoteRenderer == null) {
      throw Exception('Renderer not initialized');
    }

    _updateStatus(CameraConnectionStatus.connecting);

    try {
      Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      final Map<String, dynamic> mediaConstraints = {
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      };

      _peerConnection = await createPeerConnection(
        configuration,
        mediaConstraints,
      );

      // Add transceiver
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Setup callbacks
      _setupPeerConnectionCallbacks();

      // Create and send offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': true,
        'offerToReceiveAudio': false,
      });

      await _peerConnection!.setLocalDescription(offer);
      // Send offer to Raspberry Pi
      final response = await http
          .post(
            Uri.parse(raspUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      if (response.statusCode == 200) {
        final answerJson = jsonDecode(response.body);
        RTCSessionDescription answer = RTCSessionDescription(
          answerJson['sdp'],
          answerJson['type'],
        );

        await _peerConnection!.setRemoteDescription(answer);
        return true;
      } else {
        throw Exception('Failed to send offer: ${response.statusCode}');
      }
    } catch (e) {
      // print('Camera connection error: $e');
      _updateStatus(CameraConnectionStatus.failed);
      await disconnect();
      return false;
    }
  }

  void _setupPeerConnectionCallbacks() {
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      // print('onTrack event: ${event.track.kind}');
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _remoteRenderer?.srcObject = event.streams[0];
        _updateStatus(CameraConnectionStatus.connected);
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // print('New ICE candidate: ${candidate.candidate}');
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      // print('Connection state: $state');

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateStatus(CameraConnectionStatus.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateStatus(CameraConnectionStatus.disconnected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _updateStatus(CameraConnectionStatus.connecting);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      // print('ICE Connection state: $state');
    };
  }

  Future<void> disconnect() async {
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteRenderer?.srcObject = null;
    _updateStatus(CameraConnectionStatus.disconnected);
  }

  void _updateStatus(CameraConnectionStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _remoteRenderer?.dispose();
    _remoteRenderer = null;
    await _statusController.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
