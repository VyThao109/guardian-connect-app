part of 'root_bloc.dart';

enum ConnectionStatus { connected, disconnected, connecting }

class RootState extends Equatable {
  final int selectedTabIndex;
  final ConnectionStatus cameraStatus;
  final ConnectionStatus gpsStatus;
  final LatLng? currentLocation;
  final DateTime? lastUpdate;
  final String? address;
  final bool isSOS;
  final String companionPhoneNumber;

  const RootState({
    this.selectedTabIndex = 0,
    this.cameraStatus = ConnectionStatus.disconnected,
    this.gpsStatus = ConnectionStatus.disconnected,
    this.currentLocation,
    this.lastUpdate,
    this.address,
    this.isSOS = false,
    this.companionPhoneNumber = '',
  });

  // Initial state
  factory RootState.initial() {
    return RootState(
      selectedTabIndex: 0,
      cameraStatus: ConnectionStatus.disconnected,
      gpsStatus: ConnectionStatus.disconnected,
      currentLocation: null,
      lastUpdate: null,
      address: null,
      isSOS: false,
      companionPhoneNumber: Storage.companionPhoneNumber,
    );
  }

  // Copy with method for update state
  RootState copyWith({
    int? selectedTabIndex,
    ConnectionStatus? cameraStatus,
    ConnectionStatus? gpsStatus,
    LatLng? currentLocation,
    DateTime? lastUpdate,
    String? address,
    bool? isSOS,
    String? companionPhoneNumber,
  }) {
    return RootState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      cameraStatus: cameraStatus ?? this.cameraStatus,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      address: address ?? this.address,
      isSOS: isSOS ?? this.isSOS,
      companionPhoneNumber: companionPhoneNumber ?? this.companionPhoneNumber,
    );
  }

  bool get isCameraConnected => cameraStatus == ConnectionStatus.connected;
  bool get isGpsConnected => gpsStatus == ConnectionStatus.connected;
  bool get hasLocation => currentLocation != null;

  String get lastUpdateText {
    if (lastUpdate == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastUpdate!);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  List<Object?> get props => [
    selectedTabIndex,
    cameraStatus,
    gpsStatus,
    currentLocation,
    lastUpdate,
    companionPhoneNumber,
  ];
}
