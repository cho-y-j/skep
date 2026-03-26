import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationSubscribed extends LocationEvent {
  const LocationSubscribed();
}

class LocationUpdated extends LocationEvent {
  final double latitude;
  final double longitude;
  final String workerId;
  final String? equipmentId;
  final DateTime timestamp;

  const LocationUpdated({
    required this.latitude,
    required this.longitude,
    required this.workerId,
    this.equipmentId,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    workerId,
    equipmentId,
    timestamp,
  ];
}

class LocationUnsubscribed extends LocationEvent {
  const LocationUnsubscribed();
}
