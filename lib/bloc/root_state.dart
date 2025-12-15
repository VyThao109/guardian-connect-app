part of 'root_bloc.dart';

class RootState extends Equatable {
  final int selectedTabIndex;

  final ConnectionStatus connectionStatus;

  final LatLng? currentLocation;
  final bool hasReceivedGPSData;
  final DateTime? lastUpdate;
  final String? address;
  final bool isSOS;
  final String companionPhoneNumber;
  final String deviceIp; // IP của Raspberry Pi
  final bool isSosNotificationEnabled; // Cài đặt bật tắt thông báo
  final String emergencyPhoneNumber;

  const RootState({
    this.selectedTabIndex = 0,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.hasReceivedGPSData = false,
    this.currentLocation,
    this.lastUpdate,
    this.address,
    this.isSOS = false,
    this.companionPhoneNumber = '',
    required this.deviceIp,
    this.isSosNotificationEnabled = true,
    required this.emergencyPhoneNumber,
  });

  factory RootState.initial() {
    return RootState(
      companionPhoneNumber: Storage.companionPhoneNumber,
      emergencyPhoneNumber: Storage.emergencyNumber,
      deviceIp: Storage.ipDeviceAddress,
    );
  }

  RootState copyWith({
    int? selectedTabIndex,
    ConnectionStatus? connectionStatus,
    bool? hasReceivedGPSData,
    LatLng? currentLocation,
    DateTime? lastUpdate,
    String? address,
    bool? isSOS,
    String? companionPhoneNumber,
    String? deviceIp,
    bool? isSosNotificationEnabled,
    String? emergencyPhoneNumber,
  }) {
    return RootState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      hasReceivedGPSData: hasReceivedGPSData ?? this.hasReceivedGPSData,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      address: address ?? this.address,
      isSOS: isSOS ?? this.isSOS,
      companionPhoneNumber: companionPhoneNumber ?? this.companionPhoneNumber,
      deviceIp: deviceIp ?? this.deviceIp,
      isSosNotificationEnabled:
          isSosNotificationEnabled ?? this.isSosNotificationEnabled,
      emergencyPhoneNumber: emergencyPhoneNumber ?? this.emergencyPhoneNumber,
    );
  }

  // Helper getters cho UI
  bool get isConnected => connectionStatus == ConnectionStatus.connected;
  bool get isConnecting => connectionStatus == ConnectionStatus.connecting;
  bool get hasLocation => currentLocation != null;

  String get lastUpdateText {
    if (lastUpdate == null) return '--/--/----';
    final difference = DateTime.now().difference(lastUpdate!);
    if (difference.inSeconds < 60) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    return '${difference.inDays} ngày trước';
  }

  @override
  List<Object?> get props => [
    selectedTabIndex,
    connectionStatus,
    hasReceivedGPSData,
    currentLocation,
    lastUpdate,
    address,
    isSOS,
    companionPhoneNumber,
    deviceIp,
    isSosNotificationEnabled,
    emergencyPhoneNumber,
  ];
}
