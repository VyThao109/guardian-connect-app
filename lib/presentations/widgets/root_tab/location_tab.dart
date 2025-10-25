import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/helpers/functions.dart';
import 'package:guardian_connect_app/helpers/map_helper.dart';
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
      setState(() {
        mapReady = true;
      });
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
        final currentLocation =
            state.currentLocation ?? LatLng(16.0544, 108.2022);
        final address = state.address ?? 'Loading...';
        final lastUpdate = state.lastUpdate;
        final gpsStatus = state.isGpsConnected;

        // final double? distance = (userLocation != null)
        //     ? MapHelper.calculateDistance(currentLocation, userLocation!)
        //     : null;

        // final String? estTime = (distance != null)
        //     ? MapHelper.estimateTravelTime(distance)
        //     : null;

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
                          'Location Tracking',
                          style: TextStyle(
                            fontSize: FontSizes.large,
                            fontWeight: FontWeight.w700,
                            color: context.theme.black,
                          ),
                        ),
                        Text(
                          'Real-time location updates',
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
                        horizontal: 4,
                        vertical: 2,
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
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: gpsStatus
                                  ? context.theme.green
                                  : context.theme.grayBgColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            gpsStatus ? "Active" : "Inactive",
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
                                  userAgentPackageName:
                                      'com.example.guardian_connect',
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
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
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
                              onPressed: () => FunctionsHelper.recenterMap(
                                _mapController,
                                context,
                              ),
                              icon: Icon(Entypo.location, size: 24),
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
                                  openFullMapDialog(context, currentLocation),
                              icon: Icon(Entypo.resize_full_screen, size: 24),
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        spacing: 4,
                        children: [
                          buildLocationInfoRow(
                            context,
                            "Latitude",
                            currentLocation.latitude.toString(),
                          ),
                          buildLocationInfoRow(
                            context,
                            "Longtitude",
                            currentLocation.longitude.toString(),
                          ),
                          buildLocationInfoRow(
                            context,
                            "Address",
                            address.toString(),
                          ),
                          buildLocationInfoRow(context, "Accuracy", "+20m"),
                          // buildLocationInfoRow(
                          //   context,
                          //   "Distance",
                          //   distance != null
                          //       ? "${(distance / 1000).toStringAsFixed(2)} km"
                          //       : "Loading...",
                          // ),
                          // buildLocationInfoRow(
                          //   context,
                          //   "Est. Time",
                          //   estTime ?? "Loading...",
                          // ),
                          buildLocationInfoRow(
                            context,
                            "Last update",
                            lastUpdate != null
                                ? DateFormat(
                                    'dd/MM/yyyy HH:mm:ss',
                                  ).format(lastUpdate)
                                : "Not valid",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                DualActionButtons(
                  label1: "Refresh",
                  label2: "Open Maps",
                  icon1: Feather.refresh_ccw,
                  icon2: Feather.navigation,
                  onPressed1: () {
                    //refresh connect to gps
                  },
                  onPressed2: () async {
                    final rootState = context.read<RootBloc>().state;
                    final companionLocation = rootState.currentLocation;
                    final userLocation = await MapHelper.getCurrentLocation();

                    if (companionLocation != null && userLocation != null) {
                      await MapHelper.openMapsNavigation(
                        context: context,
                        origin: LatLng(
                          userLocation.latitude,
                          userLocation.longitude,
                        ),
                        destination: companionLocation,
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

  void openFullMapDialog(BuildContext context, LatLng currentLocation) {
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
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: isSatelliteView
                          ? 'https://{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}' // satellite
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // normal
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
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

                // Recenter button
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: mapButton(
                    icon: Entypo.location,
                    onPressed: () =>
                        FunctionsHelper.recenterMap(_mapController, context),
                  ),
                ),

                // Switch map type
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

                //  Close button
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
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: FontSizes.medium,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
