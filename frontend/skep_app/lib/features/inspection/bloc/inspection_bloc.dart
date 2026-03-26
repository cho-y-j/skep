import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/inspection/bloc/inspection_event.dart';
import 'package:skep_app/features/inspection/bloc/inspection_state.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';

class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  final DioClient dioClient;

  InspectionBloc({required this.dioClient})
      : super(const InspectionInitial()) {
    on<InspectionStarted>(_onInspectionStarted);
    on<InspectionItemsRequested>(_onItemsRequested);
    on<InspectionItemChecked>(_onItemChecked);
    on<InspectionCompleted>(_onInspectionCompleted);
  }

  Future<void> _onInspectionStarted(
    InspectionStarted event,
    Emitter<InspectionState> emit,
  ) async {
    emit(const InspectionLoading());
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.safetyInspections}/${event.inspectionId}/start',
        data: {
          'startLat': event.latitude,
          'startLon': event.longitude,
        },
      );

      if (response.statusCode == 200) {
        add(InspectionItemsRequested(inspectionId: event.inspectionId));
        return;
      }

      emit(const InspectionFailure(message: 'Failed to start inspection'));
    } catch (error) {
      emit(InspectionFailure(message: error.toString()));
    }
  }

  Future<void> _onItemsRequested(
    InspectionItemsRequested event,
    Emitter<InspectionState> emit,
  ) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '${ApiEndpoints.safetyInspections}/${event.inspectionId}/items',
      );

      if (response.statusCode == 200) {
        final items = (response.data ?? [])
            .asMap()
            .entries
            .map(
              (entry) => InspectionItem(
                id: entry.value['id'] as String? ?? '',
                title: entry.value['title'] as String? ?? '',
                description: entry.value['description'] as String? ?? '',
                itemNumber: entry.key + 1,
                totalItems: (response.data as List).length,
                isCompleted: false,
              ),
            )
            .toList();

        emit(InspectionInProgress(
          inspectionId: event.inspectionId,
          items: items,
          currentItemIndex: 0,
        ));
        return;
      }

      emit(const InspectionFailure(message: 'Failed to load inspection items'));
    } catch (error) {
      emit(InspectionFailure(message: error.toString()));
    }
  }

  Future<void> _onItemChecked(
    InspectionItemChecked event,
    Emitter<InspectionState> emit,
  ) async {
    if (state is! InspectionInProgress) return;

    final currentState = state as InspectionInProgress;

    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.safetyInspections}/${event.inspectionId}/items/${event.itemId}',
        data: {
          'passed': event.passed,
          'notes': event.notes,
        },
      );

      if (response.statusCode == 200) {
        final updatedItems = currentState.items.map((item) {
          if (item.id == event.itemId) {
            return item.copyWith(
              passed: event.passed,
              notes: event.notes,
              photoUrls: event.photoUrls,
              isCompleted: true,
            );
          }
          return item;
        }).toList();

        final nextIndex = currentState.currentItemIndex + 1;
        emit(InspectionInProgress(
          inspectionId: event.inspectionId,
          items: updatedItems,
          currentItemIndex: nextIndex,
        ));
        return;
      }

      emit(const InspectionFailure(message: 'Failed to check item'));
    } catch (error) {
      emit(InspectionFailure(message: error.toString()));
    }
  }

  Future<void> _onInspectionCompleted(
    InspectionCompleted event,
    Emitter<InspectionState> emit,
  ) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '${ApiEndpoints.safetyInspections}/${event.inspectionId}/complete',
        data: {
          'endLat': event.latitude,
          'endLon': event.longitude,
        },
      );

      if (response.statusCode == 200) {
        emit(InspectionCompletedState(inspectionId: event.inspectionId));
        return;
      }

      emit(const InspectionFailure(message: 'Failed to complete inspection'));
    } catch (error) {
      emit(InspectionFailure(message: error.toString()));
    }
  }
}
