import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ========== MODELS & ENUMS ==========

enum ConnectionStatus { disconnected, connecting, connected, failed }

class GPSData {
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  GPSData({this.latitude, this.longitude, required this.timestamp});

  factory GPSData.fromJson(Map<String, dynamic> json) {
    return GPSData(
      latitude: json['lat']?.toDouble(),
      longitude: json['lon']?.toDouble(),
      timestamp: DateTime.now(),
    );
  }
  LatLng toLatLng() => LatLng(latitude!, longitude!);
  bool get isValid => latitude != null && longitude != null;
}

class WebRTCService {
  // Config
  String _baseUrl = 'http://192.168.1.123:8000/offer'; // Default IP
  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  // Core WebRTC Objects
  RTCVideoRenderer? _remoteRenderer;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _gpsDataChannel;
  RTCDataChannel? _sosDataChannel;
  MediaStream? _remoteStream; // Lưu tham chiếu stream để pause/resume

  // State Flags
  bool _isConnecting = false;

  // Stream Controllers
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  final _gpsDataController = StreamController<GPSData>.broadcast();
  final _sosSignalController = StreamController<bool>.broadcast();

  // Getters
  Stream<ConnectionStatus> get connectionStream =>
      _connectionStatusController.stream;
  Stream<GPSData> get gpsDataStream => _gpsDataController.stream;
  Stream<bool> get sosSignalStream => _sosSignalController.stream;

  Future<void> initialize(RTCVideoRenderer renderer) async {
    _remoteRenderer = renderer;
    await _remoteRenderer?.initialize();
    if (_remoteStream != null) {
      debugPrint('Attaching pending stream to renderer');
      _remoteRenderer?.srcObject = _remoteStream;
    }
  }

  /// Cập nhật IP động từ setting
  void updateBaseUrl(String ipAddress) {
    _baseUrl = '$ipAddress/offer';
    debugPrint('WebRTC URL updated: $_baseUrl');
  }

  // CONNECTION LOGIC

  Future<bool> connect() async {
    // Prevent double connection
    if (_isConnecting ||
        _peerConnection?.connectionState ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      debugPrint('Already connecting or connected');
      return false;
    }

    _isConnecting = true;
    _updateStatus(ConnectionStatus.connecting);

    try {
      //Create Peer Connection
      _peerConnection = await createPeerConnection(_iceConfig, {});

      // Setup Data Channels (Must be before creating offer)
      await _setupDataChannels();

      // Add Video Transceiver (RecvOnly)
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Setup Callbacks
      _setupPeerCallbacks();

      // Create Offer
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': true,
        'offerToReceiveAudio': false,
      });
      await _peerConnection!.setLocalDescription(offer);

      // Send to Raspberry Pi
      debugPrint('Sending offer to: $_baseUrl');
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sdp': offer.sdp, 'type': offer.type}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final answerJson = jsonDecode(response.body);
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(answerJson['sdp'], answerJson['type']),
        );
        _isConnecting = false;
        return true;
      } else {
        throw Exception('Server rejected offer: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection Error: $e');
      await disconnect();
      _updateStatus(ConnectionStatus.failed);
      _isConnecting = false;
      return false;
    }
  }

  Future<void> _setupDataChannels() async {
    final init = RTCDataChannelInit()..ordered = true;

    // GPS Channel
    _gpsDataChannel = await _peerConnection!.createDataChannel('gps', init);
    _gpsDataChannel!.onMessage = (msg) {
      try {
        final data = GPSData.fromJson(jsonDecode(msg.text));
        if (data.isValid && !_gpsDataController.isClosed) {
          _gpsDataController.add(data);
        }
      } catch (e) {
        debugPrint('GPS Parse Error: $e');
      }
    };

    // SOS Channel
    _sosDataChannel = await _peerConnection!.createDataChannel('sos', init);
    _sosDataChannel!.onMessage = (msg) {
      debugPrint('SOS Received via WebRTC');
      if (!_sosSignalController.isClosed) {
        _sosSignalController.add(true);
      }
    };
  }

  void _setupPeerCallbacks() {
    // Monitor Connection State
    _peerConnection?.onConnectionState = (state) {
      debugPrint('Connection State: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateStatus(ConnectionStatus.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateStatus(ConnectionStatus.disconnected);
          disconnect();
          break;
        default:
          break;
      }
    };

    // Monitor Video Track
    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        final newStream = event.streams[0];
        _remoteStream = newStream; // Lưu lại

        // LOGIC MỚI: Chỉ gắn vào renderer NẾU renderer đã tồn tại (UI đã vẽ)
        if (_remoteRenderer != null) {
          if (_remoteRenderer?.srcObject?.id != newStream.id) {
            debugPrint('📹 Video Stream Attached (ID: ${newStream.id})');
            _remoteRenderer?.srcObject = newStream;
          }
        } else {
          debugPrint('Stream received but Renderer is NULL (Background mode)');
        }
      }
    };
  }

  // RESOURCE OPTIMIZATION (PAUSE/RESUME)

  /// Tạm dừng giải mã Video (Tiết kiệm CPU/Pin khi ở tab khác)
  void pauseVideoTrack() {
    // 1. Tắt giải mã track (Logic cũ)
    if (_remoteStream != null) {
      final videoTracks = _remoteStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        videoTracks.first.enabled = false;
      }
    }

    // 2. 🔥 QUAN TRỌNG: Ngắt stream khỏi renderer
    // Điều này khiến SurfaceView không còn gì để vẽ -> Hết spam log Mali
    if (_remoteRenderer != null) {
      _remoteRenderer!.srcObject = null;
    }
  }

  /// Tiếp tục giải mã Video (Khi quay lại tab Camera)
  void resumeVideoTrack() {
    // 1. Bật lại giải mã track
    if (_remoteStream != null) {
      final videoTracks = _remoteStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        videoTracks.first.enabled = true;
      }

      // 2. 🔥 QUAN TRỌNG: Gắn lại stream vào renderer
      if (_remoteRenderer != null) {
        // Chỉ gắn lại nếu chưa có (tránh nháy hình)
        if (_remoteRenderer!.srcObject != _remoteStream) {
          _remoteRenderer!.srcObject = _remoteStream;
        }
      }
    }
  }
  // CLEANUP

  Future<void> disconnect() async {
    _isConnecting = false;
    _remoteStream = null;

    // Detach stream khỏi renderer nhưng KHÔNG dispose renderer ở đây
    _remoteRenderer?.srcObject = null;

    await _gpsDataChannel?.close();
    await _sosDataChannel?.close();
    await _peerConnection?.close();

    _peerConnection = null;
    _gpsDataChannel = null;
    _sosDataChannel = null;

    _updateStatus(ConnectionStatus.disconnected);
    debugPrint('Disconnected cleanly');
  }

  void _updateStatus(ConnectionStatus status) {
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(status);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    // Chỉ dispose renderer khi tắt hẳn App
    // await _remoteRenderer?.dispose();
    // _remoteRenderer = null;

    await _connectionStatusController.close();
    await _gpsDataController.close();
    await _sosSignalController.close();
  }
}
