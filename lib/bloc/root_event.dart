part of 'root_bloc.dart';

abstract class RootEvent extends Equatable {
  const RootEvent();

  @override
  List<Object?> get props => [];
}

class ChangeTabEvent extends RootEvent {
  final int tabIndex;
  const ChangeTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class UpdateDeviceIpEvent extends RootEvent {
  final String ipAddress;
  const UpdateDeviceIpEvent(this.ipAddress);
  @override
  List<Object?> get props => [ipAddress];
}

class ConnectDeviceEvent extends RootEvent {
  const ConnectDeviceEvent();
}

class DisconnectDeviceEvent extends RootEvent {
  const DisconnectDeviceEvent();
}

class ConnectionStatusChangedEvent extends RootEvent {
  final ConnectionStatus status;
  const ConnectionStatusChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class GPSDataReceivedEvent extends RootEvent {
  final GPSData gpsData;
  const GPSDataReceivedEvent(this.gpsData);

  @override
  List<Object> get props => [gpsData];
}

class UpdateCompanionPhoneEvent extends RootEvent {
  final String phoneNumber;
  const UpdateCompanionPhoneEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class UpdateEmergencyPhoneEvent extends RootEvent {
  final String phoneNumber;
  const UpdateEmergencyPhoneEvent(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class ToggleSosNotificationSettingEvent extends RootEvent {
  final bool isEnabled;
  const ToggleSosNotificationSettingEvent(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

class TriggerEmergencyEvent extends RootEvent {
  const TriggerEmergencyEvent();
}

class ClearEmergencyEvent extends RootEvent {
  const ClearEmergencyEvent();
}

class InitializeAppEvent extends RootEvent {
  const InitializeAppEvent();
}
