import 'package:equatable/equatable.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

class DispatchWorkRecordsRequested extends DispatchEvent {
  const DispatchWorkRecordsRequested();
}

class DispatchWorkRecordCreated extends DispatchEvent {
  final String equipmentId;
  final String workerId;
  final double latitude;
  final double longitude;

  const DispatchWorkRecordCreated({
    required this.equipmentId,
    required this.workerId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [equipmentId, workerId, latitude, longitude];
}

class DispatchWorkStarted extends DispatchEvent {
  final String workRecordId;
  final double latitude;
  final double longitude;

  const DispatchWorkStarted({
    required this.workRecordId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [workRecordId, latitude, longitude];
}

class DispatchWorkEnded extends DispatchEvent {
  final String workRecordId;
  final double latitude;
  final double longitude;

  const DispatchWorkEnded({
    required this.workRecordId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [workRecordId, latitude, longitude];
}

class DispatchNFCScanned extends DispatchEvent {
  final String nfcData;

  const DispatchNFCScanned({required this.nfcData});

  @override
  List<Object?> get props => [nfcData];
}
