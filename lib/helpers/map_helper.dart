import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MapHelper {
  static Future<bool> requestLocationPermission() async {
    // Kiểm tra permission hiện tại
    PermissionStatus status = await Permission.location.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    // Nếu permanently denied, mở settings
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  /// Kiểm tra location service có bật không
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position của điện thoại
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // 1. Check location service
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // 2. Check permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw PermissionDeniedException('Location permission denied');
      }

      // 3. Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Get last known position (faster, nhưng có thể cũ)
  static Future<LatLng?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream realtime location updates
  static Stream<LatLng> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật khi di chuyển 10m
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  static String estimateTravelTime(double distanceMeters) {
    // Giả định tốc độ trung bình ~40 km/h = 11.11 m/s
    final seconds = distanceMeters / 11.11;
    final minutes = seconds / 60;
    if (minutes < 1) return "${seconds.toStringAsFixed(0)}s";
    return "${minutes.toStringAsFixed(1)} min";
  }

  static Future<void> openMapsNavigation({
    required BuildContext context,
    LatLng? origin,
    required LatLng destination,
  }) async {
    final originParam = origin != null
        ? '${origin.latitude},${origin.longitude}'
        : '';

    final destParam = '${destination.latitude},${destination.longitude}';
    late final Uri uri;

    if (Platform.isIOS) {
      uri = Uri.parse(
        'http://maps.apple.com/?saddr=$originParam&daddr=$destParam&dirflg=d',
      );
    } else {
      uri = Uri.parse('google.navigation:q=$destParam&mode=d');
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _openWebMaps(origin, destination);
      }
    } catch (e) {
      await _openWebMaps(origin, destination);
    }
  }

  static Future<void> _openWebMaps(LatLng? origin, LatLng destination) async {
    final originParam = origin != null
        ? '${origin.latitude},${origin.longitude}'
        : '';

    final webUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$originParam&destination=${destination.latitude},${destination.longitude}&travelmode=driving';

    await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
  }
}
