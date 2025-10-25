import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:guardian_connect_app/core/data/local_storage.dart';
import 'package:latlong2/latlong.dart';

part 'root_event.dart';
part 'root_state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  RootBloc() : super(RootState.initial()) {
    // Tab Navigation
    on<ChangeTabEvent>(_onChangeTab);

    // Camera Events
    on<UpdateCameraStatusEvent>(_onUpdateCameraStatus);
    on<ConnectCameraEvent>(_onConnectCamera);
    on<DisconnectCameraEvent>(_onDisconnectCamera);

    // GPS Events
    on<UpdateGpsStatusEvent>(_onUpdateGpsStatus);
    on<ConnectGpsEvent>(_onConnectGps);
    on<DisconnectGpsEvent>(_onDisconnectGps);

    // Location Events
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<RefreshLocationEvent>(_onRefreshLocation);

    // Companion Events
    on<UpdateCompanionPhoneEvent>(_onUpdateCompanionPhone);

    // Emergency Events
    on<TriggerEmergencyEvent>(_onTriggerEmergency);
    on<ClearEmergencyEvent>(_onClearEmergency);

    // Init
    on<InitializeAppEvent>(_onInitializeApp);
  }

  // ========== TAB NAVIGATION ==========
  void _onChangeTab(ChangeTabEvent event, Emitter<RootState> emit) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }

  // ========== CAMERA ==========
  void _onUpdateCameraStatus(
    UpdateCameraStatusEvent event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(cameraStatus: event.status));
  }

  Future<void> _onConnectCamera(
    ConnectCameraEvent event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(cameraStatus: ConnectionStatus.connecting));

    // Giả lập kết nối camera
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Thực tế sẽ kết nối đến camera stream
    // final success = await cameraService.connect();

    emit(state.copyWith(cameraStatus: ConnectionStatus.connected));
  }

  void _onDisconnectCamera(
    DisconnectCameraEvent event,
    Emitter<RootState> emit,
  ) {
    // TODO: Disconnect camera service
    emit(state.copyWith(cameraStatus: ConnectionStatus.disconnected));
  }

  // ========== GPS ==========
  void _onUpdateGpsStatus(UpdateGpsStatusEvent event, Emitter<RootState> emit) {
    emit(state.copyWith(gpsStatus: event.status));
  }

  Future<void> _onConnectGps(
    ConnectGpsEvent event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(gpsStatus: ConnectionStatus.connecting));

    // Giả lập kết nối GPS
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Kết nối Firebase/MQTT để nhận GPS data
    // await gpsService.connect();

    emit(state.copyWith(gpsStatus: ConnectionStatus.connected));
  }

  void _onDisconnectGps(DisconnectGpsEvent event, Emitter<RootState> emit) {
    // TODO: Disconnect GPS service
    emit(state.copyWith(gpsStatus: ConnectionStatus.disconnected));
  }

  // ========== LOCATION ==========
  void _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<RootState> emit,
  ) async {
    // Cập nhật location trước
    emit(
      state.copyWith(
        currentLocation: event.location,
        address:
            event.address ?? state.address, // Giữ address cũ nếu không có mới
        lastUpdate: DateTime.now(),
      ),
    );

    // Nếu không có address, fetch từ geocoding
    if (event.address == null) {
      try {
        final newAddress = await _getAddressFromLatLng(
          event.location.latitude,
          event.location.longitude,
        );
        emit(state.copyWith(address: newAddress));
      } catch (e) {
        emit(state.copyWith(address: 'Unknown location'));
      }
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();

        return parts.join(', ');
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      return 'Error retrieving address';
    }
  }

  Future<void> _onRefreshLocation(
    RefreshLocationEvent event,
    Emitter<RootState> emit,
  ) async {
    // TODO: Fetch location từ Firebase/MQTT
    // final location = await locationService.getCurrentLocation();

    // Giả lập data
    await Future.delayed(const Duration(seconds: 1));

    emit(
      state.copyWith(
        currentLocation: LatLng(16.0544, 108.2022),
        lastUpdate: DateTime.now(),
      ),
    );
  }

  // ========== COMPANION ==========
  void _onUpdateCompanionPhone(
    UpdateCompanionPhoneEvent event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(companionPhoneNumber: event.phoneNumber));
    Storage.setcompanionPhoneNumber(event.phoneNumber);
  }

  // ========== EMERGENCY ==========
  void _onTriggerEmergency(
    TriggerEmergencyEvent event,
    Emitter<RootState> emit,
  ) {
    // TODO: Gửi emergency alert, đổi tab sang Alert screen
    emit(state.copyWith(selectedTabIndex: 2)); // Tab Alert
    // TODO: Trigger notification, FCM, etc.
  }

  void _onClearEmergency(ClearEmergencyEvent event, Emitter<RootState> emit) {
    // TODO: Clear emergency state
  }

  // ========== INITIALIZE ==========
  Future<void> _onInitializeApp(
    InitializeAppEvent event,
    Emitter<RootState> emit,
  ) async {
    // Load saved data từ SharedPreferences/Firebase
    // final savedPhone = await prefs.getString('companion_phone');

    emit(
      state.copyWith(
        companionPhoneNumber: Storage.companionPhoneNumber,
        currentLocation: LatLng(16.0544, 108.2022),
        lastUpdate: DateTime.now(),
      ),
    );

    // Auto connect services
    add(const ConnectGpsEvent());
  }
}
