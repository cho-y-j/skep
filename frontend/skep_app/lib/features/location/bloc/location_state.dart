import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationLoaded extends LocationState {
  final List<WorkerLocation> workerLocations;

  const LocationLoaded({required this.workerLocations});

  @override
  List<Object?> get props => [workerLocations];
}

class LocationFailure extends LocationState {
  final String message;

  const LocationFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class WorkerLocation extends Equatable {
  final String workerId;
  final String workerName;
  final double latitude;
  final double longitude;
  final String? equipmentId;
  final String? equipmentName;
  final DateTime lastUpdate;
  final bool isOnline;

  const WorkerLocation({
    required this.workerId,
    required this.workerName,
    required this.latitude,
    required this.longitude,
    this.equipmentId,
    this.equipmentName,
    required this.lastUpdate,
    required this.isOnline,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  @override
  List<Object?> get props => [
    workerId,
    workerName,
    latitude,
    longitude,
    equipmentId,
    equipmentName,
    lastUpdate,
    isOnline,
  ];
}
