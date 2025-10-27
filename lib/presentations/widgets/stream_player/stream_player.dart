import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/utils/camera_service.dart';

class StreamPlayer extends StatefulWidget {
  const StreamPlayer({super.key});

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer>
    with AutomaticKeepAliveClientMixin {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late CameraService _cameraService;

  final String raspberryPiUrl = 'http://192.168.1.54:8000/offer';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cameraService = context.read<RootBloc>().cameraService;
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    await _cameraService.initialize(_remoteRenderer);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<RootBloc, RootState>(
      buildWhen: (previous, current) =>
          previous.cameraStatus != current.cameraStatus,
      builder: (context, state) {
        final isConnected = state.isCameraConnected;
        final isConnecting = state.cameraStatus == ConnectionStatus.connecting;

        return Column(
          spacing: 12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(8),
                ),
                // Video player
                child: isConnected
                    ? RTCVideoView(
                        _remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        mirror: false,
                      )
                    : _buildPlaceholder(isConnecting),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConnecting
                    ? null
                    : () {
                        if (isConnected) {
                          context.read<RootBloc>().add(DisconnectCameraEvent());
                        } else {
                          context.read<RootBloc>().add(ConnectCameraEvent());
                        }
                      },
                icon: Icon(
                  isConnecting
                      ? Icons.hourglass_empty
                      : isConnected
                      ? Icons.videocam_off
                      : Icons.videocam,
                ),
                label: Text(
                  isConnecting
                      ? 'Connecting...'
                      : isConnected
                      ? 'Stop preview'
                      : 'Start preview',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnecting
                      ? context.theme.grayBgColor
                      : context.theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(bool isLoading) {
    return Container(
      decoration: BoxDecoration(color: Color(0XFF101828)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(color: Colors.white)
            else
              Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              isLoading ? 'Connecting...' : 'Camera not connected',
              style: TextStyle(
                color: Color(0XFF99A1AF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              isLoading ? 'Please wait' : 'Click Start to begin streaming',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
