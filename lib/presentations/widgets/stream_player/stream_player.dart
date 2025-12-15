import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/presentations/widgets/button/common_button.dart';
import 'package:guardian_connect_app/core/services/web_rtc_service.dart';

class StreamPlayer extends StatefulWidget {
  const StreamPlayer({super.key});

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isRendererInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  Future<void> _initializeRenderer() async {
    await context.read<RootBloc>().webrtcService.initialize(_remoteRenderer);
    if (mounted) {
      setState(() {
        _isRendererInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRendererInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Dùng BlocSelector để chỉ rebuild khi connectionStatus thay đổi
    // GPS thay đổi sẽ không làm rebuild widget này
    return BlocBuilder<RootBloc, RootState>(
      buildWhen: (previous, current) =>
          previous.connectionStatus != current.connectionStatus ||
          previous.selectedTabIndex != current.selectedTabIndex,
      builder: (context, state) {
        final isConnected =
            state.connectionStatus == ConnectionStatus.connected;
        final isConnecting =
            state.connectionStatus == ConnectionStatus.connecting;
        final isCameraTab = state.selectedTabIndex == 0;
        final shouldShowVideo = isConnected && isCameraTab;

        return Column(
          spacing: 12,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: shouldShowVideo
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: false,
                      filterQuality: FilterQuality.none,
                    )
                  : _buildPlaceholder(context, isConnecting),
            ),

            // ),
            if (!isConnected && !isConnecting)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CommonButton(
                  label: 'Thử kết nối lại',
                  icon: Feather.refresh_cw,
                  onPressed: () {
                    context.read<RootBloc>().add(const ConnectDeviceEvent());
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isLoading) {
    return Container(
      color: const Color(0XFF101828),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: Colors.white.withAlpha(50),
            ),
            const SizedBox(height: 16),
            Text(
              isLoading ? 'Đang thiết lập kết nối...' : 'Chưa kết nối thiết bị',
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading
                  ? 'Vui lòng đợi trong giây lát'
                  : 'Nhấn nút bên dưới để bắt đầu',
              style: TextStyle(
                color: Colors.white.withAlpha(125),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
