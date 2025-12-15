import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:guardian_connect_app/core/data/local_storage.dart';
import 'package:guardian_connect_app/core/services/sos_notification_service.dart';
import 'package:guardian_connect_app/core/services/web_rtc_service.dart';
import 'package:latlong2/latlong.dart';

part 'root_event.dart';
part 'root_state.dart';

class RootBloc extends Bloc<RootEvent, RootState> {
  final WebRTCService webrtcService;
  final SOSNotificationService sosService;

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _gpsDataSubscription;
  StreamSubscription? _sosSignalSubscription;

  RootBloc({required this.webrtcService, required this.sosService})
    : super(RootState.initial()) {
    on<ChangeTabEvent>(_onChangeTab);
    on<ConnectDeviceEvent>(_onConnectDevice);
    on<DisconnectDeviceEvent>(_onDisconnectDevice);
    on<ConnectionStatusChangedEvent>(_onConnectionStatusChanged);

    on<GPSDataReceivedEvent>(_onGPSDataReceived);
    on<UpdateCompanionPhoneEvent>(_onUpdateCompanionPhone);
    on<TriggerEmergencyEvent>(_onTriggerEmergency);
    on<ClearEmergencyEvent>(_onClearEmergency);
    on<UpdateDeviceIpEvent>(_onUpdateDeviceIp);
    on<ToggleSosNotificationSettingEvent>(_onToggleSosNotification);
    on<UpdateEmergencyPhoneEvent>(_onUpdateEmergencyPhone);
    on<InitializeAppEvent>(_onInitializeApp);

    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // 1. Lắng nghe trạng thái kết nối chung
    _connectionSubscription = webrtcService.connectionStream.listen((status) {
      add(ConnectionStatusChangedEvent(status));
    });

    // 2. Lắng nghe dữ liệu GPS
    _gpsDataSubscription = webrtcService.gpsDataStream.listen((gpsData) {
      add(GPSDataReceivedEvent(gpsData));
    });

    // 3. Lắng nghe tín hiệu SOS từ WebRTC
    _sosSignalSubscription = webrtcService.sosSignalStream.listen((_) {
      add(const TriggerEmergencyEvent());
    });
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<RootState> emit) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
    if (state.connectionStatus == ConnectionStatus.connected) {
      if (event.tabIndex == 0) {
        // Vào tab Camera -> Bật hình
        webrtcService.resumeVideoTrack();
      } else {
        // Sang tab khác (Map/Alert) -> Tắt hình
        webrtcService.pauseVideoTrack();
      }
    }
  }

  Future<void> _onUpdateDeviceIp(
    UpdateDeviceIpEvent event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(deviceIp: event.ipAddress));
    await Storage.setIpDeviceAddress(event.ipAddress);
    webrtcService.updateBaseUrl(event.ipAddress);
    if (state.connectionStatus == ConnectionStatus.connected ||
        state.connectionStatus == ConnectionStatus.connecting) {
      add(const DisconnectDeviceEvent());
      add(const ConnectDeviceEvent());
    }
  }

  Future<void> _onConnectDevice(
    ConnectDeviceEvent event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting));

    final success = await webrtcService.connect();

    if (!success) {
      emit(state.copyWith(connectionStatus: ConnectionStatus.failed));
    }
  }

  Future<void> _onDisconnectDevice(
    DisconnectDeviceEvent event,
    Emitter<RootState> emit,
  ) async {
    await webrtcService.disconnect();
    emit(state.copyWith(connectionStatus: ConnectionStatus.disconnected));
  }

  void _onConnectionStatusChanged(
    ConnectionStatusChangedEvent event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(connectionStatus: event.status));
    if (event.status == ConnectionStatus.connected) {
      if (state.selectedTabIndex == 0) {
        webrtcService.resumeVideoTrack(); // Tab 0 là Camera -> Bật
      } else {
        webrtcService.pauseVideoTrack(); // Tab khác -> Tắt cho nhẹ
      }
    }
  }

  void _onGPSDataReceived(
    GPSDataReceivedEvent event,
    Emitter<RootState> emit,
  ) async {
    final gpsData = event.gpsData;
    if (!gpsData.isValid) return;

    emit(
      state.copyWith(
        currentLocation: gpsData.toLatLng(),
        lastUpdate: gpsData.timestamp,
        hasReceivedGPSData: true,
      ),
    );

    try {
      final address = await _getAddressFromLatLng(
        gpsData.latitude!,
        gpsData.longitude!,
      );
      if (!isClosed) {
        emit(state.copyWith(address: address));
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
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
        ].where((e) => e != null && e.isNotEmpty).toList();

        return parts.isNotEmpty ? parts.join(', ') : 'Không xác định';
      }
      return 'Không xác định';
    } catch (e) {
      return 'Lỗi lấy địa chỉ';
    }
  }

  void _onUpdateCompanionPhone(
    UpdateCompanionPhoneEvent event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(companionPhoneNumber: event.phoneNumber));
    Storage.setcompanionPhoneNumber(event.phoneNumber);
  }

  Future<void> _onToggleSosNotification(
    ToggleSosNotificationSettingEvent event,
    Emitter<RootState> emit,
  ) async {
    emit(state.copyWith(isSosNotificationEnabled: event.isEnabled));
    await sosService.setMasterNotificationEnabled(event.isEnabled);
  }

  void _onUpdateEmergencyPhone(
    UpdateEmergencyPhoneEvent event,
    Emitter<RootState> emit,
  ) {
    emit(state.copyWith(emergencyPhoneNumber: event.phoneNumber));
    Storage.setEmergencyNumber(event.phoneNumber);
  }

  Future<void> _onTriggerEmergency(
    TriggerEmergencyEvent event,
    Emitter<RootState> emit,
  ) async {
    await sosService.showSOSNotification();
    emit(state.copyWith(selectedTabIndex: 2, isSOS: true));
  }

  Future<void> _onClearEmergency(
    ClearEmergencyEvent event,
    Emitter<RootState> emit,
  ) async {
    await sosService.cancelSOSNotification();
    emit(state.copyWith(isSOS: false));
  }

  Future<void> _onInitializeApp(
    InitializeAppEvent event,
    Emitter<RootState> emit,
  ) async {
    final savedIp = Storage.ipDeviceAddress;

    webrtcService.updateBaseUrl(savedIp);

    final isSosEnabled = await sosService.isMasterNotificationEnabled();

    emit(
      state.copyWith(
        companionPhoneNumber: Storage.companionPhoneNumber,
        emergencyPhoneNumber: Storage.emergencyNumber,
        deviceIp: savedIp,

        isSosNotificationEnabled: isSosEnabled,
      ),
    );
    add(const ConnectDeviceEvent());
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _gpsDataSubscription?.cancel();
    _sosSignalSubscription?.cancel();
    webrtcService.dispose();
    return super.close();
  }
}
