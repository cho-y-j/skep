import 'package:equatable/equatable.dart';

abstract class InspectionEvent extends Equatable {
  const InspectionEvent();

  @override
  List<Object?> get props => [];
}

class InspectionStarted extends InspectionEvent {
  final String inspectionId;
  final double latitude;
  final double longitude;

  const InspectionStarted({
    required this.inspectionId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [inspectionId, latitude, longitude];
}

class InspectionItemChecked extends InspectionEvent {
  final String inspectionId;
  final String itemId;
  final bool passed;
  final String? notes;
  final List<String>? photoUrls;

  const InspectionItemChecked({
    required this.inspectionId,
    required this.itemId,
    required this.passed,
    this.notes,
    this.photoUrls,
  });

  @override
  List<Object?> get props => [inspectionId, itemId, passed, notes, photoUrls];
}

class InspectionCompleted extends InspectionEvent {
  final String inspectionId;
  final double latitude;
  final double longitude;

  const InspectionCompleted({
    required this.inspectionId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [inspectionId, latitude, longitude];
}

class InspectionItemsRequested extends InspectionEvent {
  final String inspectionId;

  const InspectionItemsRequested({required this.inspectionId});

  @override
  List<Object?> get props => [inspectionId];
}
