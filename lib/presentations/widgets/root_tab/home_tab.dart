import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/presentations/widgets/container/quick_actions.dart';
import 'package:guardian_connect_app/presentations/widgets/stream_player/stream_player.dart';
import 'package:guardian_connect_app/utils/functions.dart';
import 'package:guardian_connect_app/core/services/web_rtc_service.dart';
import 'package:latlong2/latlong.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 24,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStreamVideoSection(context),

          _buildLocationViewSection(context),

          const QuickActionsContainer(),
        ],
      ),
    );
  }

  Widget _buildStreamVideoSection(BuildContext context) {
    return BlocSelector<RootBloc, RootState, ConnectionStatus>(
      selector: (state) => state.connectionStatus,
      builder: (context, status) {
        final isConnected = status == ConnectionStatus.connected;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            spacing: 20,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        'Camera trực tiếp',
                        style: TextStyle(
                          fontSize: FontSizes.large,
                          fontWeight: FontWeight.w700,
                          color: context.theme.black,
                        ),
                      ),
                      Text(
                        'Góc nhìn từ thiết bị người thân',
                        style: TextStyle(
                          fontSize: FontSizes.small,
                          color: context.theme.grayTextColor,
                        ),
                      ),
                    ],
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      spacing: 4,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? context.theme.green
                                : context.theme.grayBgColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          isConnected ? "Trực tiếp" : "Đã dừng",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: FontSizes.small,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Player
              const StreamPlayer(),

              // Note box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: context.theme.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bạn đang xem hình ảnh trực tiếp từ thiết bị của người thân.",
                        style: TextStyle(
                          color: context.theme.blue,
                          fontSize: FontSizes.small,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationViewSection(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      buildWhen: (previous, current) =>
          previous.currentLocation != current.currentLocation ||
          previous.address != current.address ||
          previous.lastUpdate != current.lastUpdate,
      builder: (context, state) {
        final companionLocation = state.currentLocation;
        final address = state.address ?? 'Đang cập nhật vị trí...';
        final lastUpdate = state.lastUpdateText;

        final LatLng displayLocation =
            companionLocation ??
            const LatLng(16.047079, 108.206230); // Default Da Nang

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text(
              "Vị trí hiện tại",
              style: TextStyle(
                color: context.theme.black,
                fontSize: FontSizes.large,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: displayLocation,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.guardian_connect',
                        ),
                        MarkerLayer(
                          markers: [
                            if (companionLocation != null)
                              Marker(
                                point: companionLocation,
                                width: 80,
                                height: 80,
                                child: Icon(
                                  Icons.location_on,
                                  color: context.theme.red,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Info Card Overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 60,
                    child: GestureDetector(
                      onTap: () => FunctionsHelper.recenterMap(
                        _mapController, // Recenter map
                        context,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(225),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              companionLocation != null
                                  ? address
                                  : "Đang cập nhật...",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: FontSizes.medium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cập nhật: $lastUpdate',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: FontSizes.small - 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation Button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: "nav_btn_home",
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      child: const Icon(Icons.navigation_outlined),
                      onPressed: () =>
                          context.read<RootBloc>().add(const ChangeTabEvent(1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
