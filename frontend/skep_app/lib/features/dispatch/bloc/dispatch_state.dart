import 'package:equatable/equatable.dart';

abstract class DispatchState extends Equatable {
  const DispatchState();

  @override
  List<Object?> get props => [];
}

class DispatchInitial extends DispatchState {
  const DispatchInitial();
}

class DispatchLoading extends DispatchState {
  const DispatchLoading();
}

class DispatchWorkRecordsLoaded extends DispatchState {
  final List<WorkRecord> workRecords;

  const DispatchWorkRecordsLoaded({required this.workRecords});

  @override
  List<Object?> get props => [workRecords];
}

class DispatchWorkStartedState extends DispatchState {
  final String workRecordId;
  final DateTime startTime;

  const DispatchWorkStartedState({
    required this.workRecordId,
    required this.startTime,
  });

  @override
  List<Object?> get props => [workRecordId, startTime];
}

class DispatchWorkEndedState extends DispatchState {
  final String workRecordId;
  final DateTime endTime;

  const DispatchWorkEndedState({
    required this.workRecordId,
    required this.endTime,
  });

  @override
  List<Object?> get props => [workRecordId, endTime];
}

class DispatchNFCDetected extends DispatchState {
  final String nfcData;

  const DispatchNFCDetected({required this.nfcData});

  @override
  List<Object?> get props => [nfcData];
}

class DispatchFailure extends DispatchState {
  final String message;

  const DispatchFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class WorkRecord extends Equatable {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String workerId;
  final String workerName;
  final DateTime checkinTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final double checkinLat;
  final double checkinLon;
  final String status;

  const WorkRecord({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.workerId,
    required this.workerName,
    required this.checkinTime,
    this.startTime,
    this.endTime,
    required this.checkinLat,
    required this.checkinLon,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        equipmentId,
        equipmentName,
        workerId,
        workerName,
        checkinTime,
        startTime,
        endTime,
        checkinLat,
        checkinLon,
        status,
      ];
}
