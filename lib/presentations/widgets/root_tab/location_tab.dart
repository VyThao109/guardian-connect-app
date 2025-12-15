import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/utils/functions.dart';
import 'package:guardian_connect_app/utils/map_helper.dart';
import 'package:guardian_connect_app/presentations/widgets/button/dual_action_buttons.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  final MapController _mapController = MapController();
  bool mapReady = false;

  LatLng? userLocation;
  bool isSatelliteView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          mapReady = true;
        });
      }
    });
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await MapHelper.getCurrentLocation();
    if (mounted) {
      setState(() {
        userLocation = location;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      builder: (context, state) {
        final hasGPSData = state.hasReceivedGPSData;
        final isConnected = state.isConnected;
        final currentLocation = state.currentLocation;
        final address = state.address;
        final lastUpdate = state.lastUpdate;

        // 1. Nếu có vị trí Rasp -> Dùng Rasp
        // 2. Nếu không, dùng vị trí điện thoại (userLocation)
        // 3. Nếu không, dùng mặc định (VD: Hà Nội/Đà Nẵng) để tránh màn hình xám
        final LatLng displayLocation =
            currentLocation ??
            userLocation ??
            const LatLng(16.047079, 108.206230); // Default Da Nang

        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.theme.grayBgColor ?? Colors.grey,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              spacing: 20,
              children: [
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
                          'Theo dõi vị trí',
                          style: TextStyle(
                            fontSize: FontSizes.large,
                            fontWeight: FontWeight.w700,
                            color: context.theme.black,
                          ),
                        ),
                        Text(
                          'Cập nhật vị trí thời gian thực',
                          style: TextStyle(
                            fontSize: FontSizes.small,
                            fontWeight: FontWeight.normal,
                            color: context.theme.grayTextColor,
                          ),
                        ),
                      ],
                    ),
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
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? (hasGPSData
                                        ? context.theme.green
                                        : Colors.orange)
                                  : context.theme.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            isConnected && hasGPSData
                                ? "Đang hoạt động"
                                : isConnected
                                ? "Chờ dữ liệu..."
                                : "Mất kết nối",
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

                Column(
                  spacing: 12,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 400,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: displayLocation,
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
                                  urlTemplate: isSatelliteView
                                      ? 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  subdomains: const [
                                    'mt0',
                                    'mt1',
                                    'mt2',
                                    'mt3',
                                  ],
                                  userAgentPackageName:
                                      'com.example.guardian_connect',
                                ),
                                MarkerLayer(
                                  markers: [
                                    if (currentLocation != null)
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
                                    if (userLocation != null)
                                      Marker(
                                        point: userLocation!,
                                        width: 40,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                (context.theme.primaryColor ??
                                                        Colors.blue)
                                                    .withAlpha(50),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  context.theme.primaryColor ??
                                                  Colors.blue,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            color:
                                                context.theme.primaryColor ??
                                                Colors.blue,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Các nút điều khiển bản đồ giữ nguyên
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: mapButton(
                            icon: Entypo.location,
                            onPressed: () => FunctionsHelper.recenterMap(
                              _mapController,
                              context,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: mapButton(
                            icon: isSatelliteView
                                ? Icons.map
                                : Icons.satellite_alt,
                            onPressed: () {
                              setState(() {
                                isSatelliteView = !isSatelliteView;
                              });
                            },
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: mapButton(
                            icon: Entypo.resize_full_screen,
                            onPressed: () => openFullMapDialog(
                              context,
                              currentLocation ?? displayLocation,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Thông tin chi tiết
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        spacing: 4,
                        children: [
                          buildLocationInfoRow(
                            context,
                            "Vĩ độ",
                            currentLocation?.latitude.toString() ??
                                "Đang cập nhật...",
                          ),
                          buildLocationInfoRow(
                            context,
                            "Kinh độ",
                            currentLocation?.longitude.toString() ??
                                "Đang cập nhật...",
                          ),
                          buildLocationInfoRow(
                            context,
                            "Địa chỉ",
                            address ?? "Đang cập nhật...",
                          ),
                          buildLocationInfoRow(
                            context,
                            "Độ chính xác",
                            hasGPSData ? "Cao" : "--",
                          ),
                          buildLocationInfoRow(
                            context,
                            "Cập nhật cuối",
                            lastUpdate != null
                                ? DateFormat(
                                    'HH:mm:ss dd/MM/yyyy',
                                  ).format(lastUpdate)
                                : "--/--/----",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                DualActionButtons(
                  label1: "Làm mới",
                  label2: "Chỉ đường",
                  icon1: Feather.refresh_cw,
                  icon2: Feather.navigation,
                  onPressed1: () {
                    // Nếu chưa kết nối thì thử kết nối lại
                    if (!isConnected) {
                      context.read<RootBloc>().add(const ConnectDeviceEvent());
                    }
                  },
                  onPressed2: () async {
                    if (currentLocation != null && userLocation != null) {
                      await MapHelper.openMapsNavigation(
                        context: context,
                        origin: userLocation, // Đã có sẵn latlong
                        destination: currentLocation,
                      );
                    } else {
                      // Thông báo nếu chưa có toạ độ
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Chưa có thông tin vị trí để chỉ đường",
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openFullMapDialog(BuildContext context, LatLng centerLocation) {
    final MapController localMapController = MapController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withAlpha(30),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                FlutterMap(
                  mapController: localMapController,
                  options: MapOptions(
                    initialCenter: centerLocation,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isSatelliteView
                          ? 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                      userAgentPackageName: 'com.example.guardian_connect',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker 1: Rasp hoặc Default
                        Marker(
                          point: centerLocation,
                          width: 80,
                          height: 80,
                          child: Icon(
                            Icons.location_on,
                            color: context.theme.red,
                            size: 40,
                          ),
                        ),

                        // Marker 2: Vị trí điện thoại của bạn
                        if (userLocation != null)
                          Marker(
                            point: userLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    (context.theme.primaryColor ?? Colors.blue)
                                        .withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      context.theme.primaryColor ?? Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.circle,
                                color:
                                    context.theme.primaryColor ?? Colors.blue,
                                size: 15,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Các nút điều khiển (Sửa lại để dùng localMapController)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: mapButton(
                    icon: Entypo.location,
                    onPressed: () => FunctionsHelper.recenterMap(
                      localMapController, // Recenter map
                      context,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 10,
                  right: 10,
                  child: mapButton(
                    icon: isSatelliteView ? Icons.map : Icons.satellite_alt,
                    onPressed: () {
                      setStateDialog(() {
                        isSatelliteView = !isSatelliteView;
                      });
                    },
                  ),
                ),

                Positioned(
                  top: 30,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black12.withAlpha(42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.theme.grayTextColor,
                        size: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget mapButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
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
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.all(4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget buildLocationInfoRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.theme.black,
            fontSize: FontSizes.small,
            fontWeight: FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: FontSizes.medium,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
