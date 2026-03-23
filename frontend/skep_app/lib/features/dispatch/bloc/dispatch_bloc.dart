import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_event.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_state.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final DioClient dioClient;

  DispatchBloc({required this.dioClient}) : super(const DispatchInitial()) {
    on<DispatchWorkRecordsRequested>(_onWorkRecordsRequested);
    on<DispatchWorkRecordCreated>(_onWorkRecordCreated);
    on<DispatchWorkStarted>(_onWorkStarted);
    on<DispatchWorkEnded>(_onWorkEnded);
    on<DispatchNFCScanned>(_onNFCScanned);
  }

  Future<void> _onWorkRecordsRequested(
    DispatchWorkRecordsRequested event,
    Emitter<DispatchState> emit,
  ) async {
    emit(const DispatchLoading());
    try {
      final response = await dioClient.get<List<dynamic>>(
        ApiEndpoints.workRecords,
      );

      if (response.statusCode == 200) {
        final records = (response.data ?? [])
            .map((json) => _parseWorkRecord(json as Map<String, dynamic>))
            .toList();
        emit(DispatchWorkRecordsLoaded(workRecords: records));
        return;
      }

      emit(const DispatchFailure(message: 'Failed to load work records'));
    } catch (error) {
      emit(DispatchFailure(message: error.toString()));
    }
  }

  Future<void> _onWorkRecordCreated(
    DispatchWorkRecordCreated event,
    Emitter<DispatchState> emit,
  ) async {
    emit(const DispatchLoading());
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        ApiEndpoints.workRecords,
        data: {
          'equipmentId': event.equipmentId,
          'workerId': event.workerId,
          'checkinLat': event.latitude,
          'checkinLon': event.longitude,
          'status': 'CHECKED_IN',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(const DispatchLoading());
        add(const DispatchWorkRecordsRequested());
        return;
      }

      emit(const DispatchFailure(message: 'Failed to create work record'));
    } catch (error) {
      emit(DispatchFailure(message: error.toString()));
    }
  }

  Future<void> _onWorkStarted(
    DispatchWorkStarted event,
    Emitter<DispatchState> emit,
  ) async {
    emit(const DispatchLoading());
    try {
      final url = ApiEndpoints.startWork
          .replaceAll('{id}', event.workRecordId);
      final response = await dioClient.post<Map<String, dynamic>>(
        url,
        data: {
          'startLat': event.latitude,
          'startLon': event.longitude,
        },
      );

      if (response.statusCode == 200) {
        emit(DispatchWorkStartedState(
          workRecordId: event.workRecordId,
          startTime: DateTime.now(),
        ));
        add(const DispatchWorkRecordsRequested());
        return;
      }

      emit(const DispatchFailure(message: 'Failed to start work'));
    } catch (error) {
      emit(DispatchFailure(message: error.toString()));
    }
  }

  Future<void> _onWorkEnded(
    DispatchWorkEnded event,
    Emitter<DispatchState> emit,
  ) async {
    emit(const DispatchLoading());
    try {
      final url = ApiEndpoints.endWork
          .replaceAll('{id}', event.workRecordId);
      final response = await dioClient.post<Map<String, dynamic>>(
        url,
        data: {
          'endLat': event.latitude,
          'endLon': event.longitude,
        },
      );

      if (response.statusCode == 200) {
        emit(DispatchWorkEndedState(
          workRecordId: event.workRecordId,
          endTime: DateTime.now(),
        ));
        add(const DispatchWorkRecordsRequested());
        return;
      }

      emit(const DispatchFailure(message: 'Failed to end work'));
    } catch (error) {
      emit(DispatchFailure(message: error.toString()));
    }
  }

  Future<void> _onNFCScanned(
    DispatchNFCScanned event,
    Emitter<DispatchState> emit,
  ) async {
    emit(DispatchNFCDetected(nfcData: event.nfcData));
  }

  WorkRecord _parseWorkRecord(Map<String, dynamic> json) {
    return WorkRecord(
      id: json['id'] as String? ?? '',
      equipmentId: json['equipmentId'] as String? ?? '',
      equipmentName: json['equipmentName'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      workerName: json['workerName'] as String? ?? '',
      checkinTime: DateTime.parse(json['checkinTime'] as String? ?? DateTime.now().toIso8601String()),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      checkinLat: (json['checkinLat'] as num?)?.toDouble() ?? 0.0,
      checkinLon: (json['checkinLon'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'CHECKED_IN',
    );
  }
}
