import 'package:equatable/equatable.dart';

abstract class InspectionState extends Equatable {
  const InspectionState();

  @override
  List<Object?> get props => [];
}

class InspectionInitial extends InspectionState {
  const InspectionInitial();
}

class InspectionLoading extends InspectionState {
  const InspectionLoading();
}

class InspectionInProgress extends InspectionState {
  final String inspectionId;
  final List<InspectionItem> items;
  final int currentItemIndex;

  const InspectionInProgress({
    required this.inspectionId,
    required this.items,
    this.currentItemIndex = 0,
  });

  @override
  List<Object?> get props => [inspectionId, items, currentItemIndex];
}

class InspectionItemsLoaded extends InspectionState {
  final List<InspectionItem> items;

  const InspectionItemsLoaded({required this.items});

  @override
  List<Object?> get props => [items];
}

class InspectionCompletedState extends InspectionState {
  final String inspectionId;

  const InspectionCompletedState({required this.inspectionId});

  @override
  List<Object?> get props => [inspectionId];
}

class InspectionFailure extends InspectionState {
  final String message;

  const InspectionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class InspectionItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final int itemNumber;
  final int totalItems;
  final bool? passed;
  final String? notes;
  final List<String>? photoUrls;
  final bool isCompleted;

  const InspectionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.itemNumber,
    required this.totalItems,
    this.passed,
    this.notes,
    this.photoUrls,
    this.isCompleted = false,
  });

  InspectionItem copyWith({
    String? id,
    String? title,
    String? description,
    int? itemNumber,
    int? totalItems,
    bool? passed,
    String? notes,
    List<String>? photoUrls,
    bool? isCompleted,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      itemNumber: itemNumber ?? this.itemNumber,
      totalItems: totalItems ?? this.totalItems,
      passed: passed ?? this.passed,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        itemNumber,
        totalItems,
        passed,
        notes,
        photoUrls,
        isCompleted,
      ];
}
