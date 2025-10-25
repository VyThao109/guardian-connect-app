part of 'root_bloc.dart';

abstract class RootEvent extends Equatable {
  const RootEvent();

  @override
  List<Object?> get props => [];
}

// Change tab
class ChangeTabEvent extends RootEvent {
  final int tabIndex;

  const ChangeTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

// Camera
class UpdateCameraStatusEvent extends RootEvent {
  final ConnectionStatus status;

  const UpdateCameraStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class ConnectCameraEvent extends RootEvent {
  const ConnectCameraEvent();
}

class DisconnectCameraEvent extends RootEvent {
  const DisconnectCameraEvent();
}

// GPS
class UpdateGpsStatusEvent extends RootEvent {
  final ConnectionStatus status;

  const UpdateGpsStatusEvent(this.status);

  @override
  List<Object?> get props => [status];
}

class ConnectGpsEvent extends RootEvent {
  const ConnectGpsEvent();
}

class DisconnectGpsEvent extends RootEvent {
  const DisconnectGpsEvent();
}

class UpdateLocationEvent extends RootEvent {
  final LatLng location;
  final String? address;

  const UpdateLocationEvent({required this.location, this.address});

  @override
  List<Object?> get props => [location, address];
}

class RefreshLocationEvent extends RootEvent {
  const RefreshLocationEvent();
}

// SOS
class UpdateSOSEvent extends RootEvent {
  final bool isSOS;

  const UpdateSOSEvent(this.isSOS);

  @override
  List<Object?> get props => [isSOS];
}

// Companion
class UpdateCompanionPhoneEvent extends RootEvent {
  final String phoneNumber;

  const UpdateCompanionPhoneEvent(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

// Emergency Events
class TriggerEmergencyEvent extends RootEvent {
  const TriggerEmergencyEvent();
}

class ClearEmergencyEvent extends RootEvent {
  const ClearEmergencyEvent();
}

// Init Event
class InitializeAppEvent extends RootEvent {
  const InitializeAppEvent();
}
