import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/utils/functions.dart';
import 'package:guardian_connect_app/presentations/widgets/button/dual_action_buttons.dart';
import 'package:guardian_connect_app/presentations/widgets/stream_player/stream_player.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final MapController _mapController = MapController();
  bool mapReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        mapReady = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            spacing: 24,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildStreamVideoSection(context, state),
              buildLocationViewSection(context, state),
              buildActionBtnsSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget buildStreamVideoSection(BuildContext context, RootState state) {
    final isStreaming = state.cameraStatus == ConnectionStatus.connected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: context.theme.grayBgColor ?? Colors.grey),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 20,
        children: [
          //header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'Live Camera Feed',
                    style: TextStyle(
                      fontSize: FontSizes.large,
                      fontWeight: FontWeight.w700,
                      color: context.theme.black,
                    ),
                  ),
                  Text(
                    'View from companion\'s device',
                    style: TextStyle(
                      fontSize: FontSizes.small,
                      fontWeight: FontWeight.normal,
                      color: context.theme.grayTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  spacing: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isStreaming
                            ? context.theme.red
                            : context.theme.grayBgColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      isStreaming ? "Live" : "Stopped",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: FontSizes.small,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          //video player
          Column(
            spacing: 12,
            children: [
              StreamPlayer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.theme.blue300,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.theme.blue500 ?? Colors.blue,
                  ),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Note: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.theme.blue,
                          fontSize: FontSizes.medium,
                          height: 1.5,
                        ),
                      ),
                      TextSpan(
                        text:
                            "You are now watching the live view from your visually impaired companion's device.",
                        style: TextStyle(
                          color: context.theme.blue,
                          fontSize: FontSizes.medium,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildLocationViewSection(BuildContext context, RootState state) {
    final currentLocation = state.currentLocation ?? LatLng(16.0544, 108.2022);
    final address = state.address ?? 'Loading...';
    final lastUpdate = state.lastUpdateText;
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          "Companion's current Location",
          style: TextStyle(
            color: context.theme.black,
            fontSize: FontSizes.large,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        ),
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onMapReady: () {
                      setState(() {
                        mapReady = true;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.guardian_connect',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
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
              Positioned(
                bottom: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () =>
                      FunctionsHelper.recenterMap(_mapController, context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(62),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Current location',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: FontSizes.medium,
                          ),
                        ),
                        Text(
                          '$address\nUpdated $lastUpdate',
                          style: TextStyle(
                            color: context.theme.black,
                            fontSize: FontSizes.small,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(62),
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () =>
                        context.read<RootBloc>().add(ChangeTabEvent(1)),
                    icon: Icon(Feather.navigation, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildActionBtnsSection(BuildContext context, RootState state) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            color: context.theme.black,
            fontSize: FontSizes.large,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.left,
        ),
        DualActionButtons(
          label1: "Reach companion",
          label2: "Emergency call",
          icon1: Ionicons.call_outline,
          icon2: AntDesign.warning,
          onPressed1: () {
            FunctionsHelper.showContactModal(context);
          },
          onPressed2: () async {
            await launchUrl(
              Uri(scheme: 'tel', path: "115"),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ],
    );
  }
}
