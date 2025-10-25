import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/presentations/widgets/modal/contact_modal.dart';

class FunctionsHelper {
  static void recenterMap(MapController mapController, BuildContext context) {
    if (!mapController.mapEventStream.isBroadcast) {
      return;
    }

    final currentLocation = context.read<RootBloc>().state.currentLocation;
    if (currentLocation == null) return;

    try {
      mapController.move(currentLocation, 15);
      mapController.moveAndRotate(currentLocation, 15, 0);
    } catch (e) {
      // Handle error silently
    }
  }

  static void showContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return ContactModal();
      },
    );
  }
}
