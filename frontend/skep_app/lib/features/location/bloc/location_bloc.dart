import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/network/dio_client.dart';
import 'package:skep_app/features/location/bloc/location_event.dart';
import 'package:skep_app/features/location/bloc/location_state.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final DioClient dioClient;
  StompClient? _stompClient;
  List<WorkerLocation> _currentLocations = [];

  LocationBloc({required this.dioClient}) : super(const LocationInitial()) {
    on<LocationSubscribed>(_onLocationSubscribed);
    on<LocationUpdated>(_onLocationUpdated);
    on<LocationUnsubscribed>(_onLocationUnsubscribed);
  }

  Future<void> _onLocationSubscribed(
    LocationSubscribed event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationLoading());
    try {
      _stompClient = StompClient(
        config: StompConfig(
          url: '${ApiEndpoints.wsBase}/ws/locations',
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) {
            print('WebSocket error: $error');
          },
          beforeConnect: () async {
            print('Waiting to connect...');
          },
        ),
      );

      _stompClient!.activate();
    } catch (error) {
      emit(LocationFailure(message: error.toString()));
    }
  }

  void _onConnect(StompFrame frame) {
    print('Connected to WebSocket');
    _stompClient!.subscribe(
      destination: '/topic/worker-locations',
      callback: (frame) {
        final locationData = frame.body;
        if (locationData != null) {
          _processLocationUpdate(locationData);
        }
      },
    );

    if (state is LocationLoading) {
      add(LocationUpdated(
        latitude: 0,
        longitude: 0,
        workerId: '',
        timestamp: DateTime.now(),
      ));
    }
  }

  void _onDisconnect(StompFrame frame) {
    print('Disconnected from WebSocket');
  }

  // Note: stomp_dart_client doesn't expose onDisconnect via StompConfig directly.
  // The _onDisconnect is kept for reference but won't be called via config.

  void _processLocationUpdate(String locationData) {
    try {
      // Parse location data from WebSocket message
      // Expected format: {"workerId":"123","latitude":37.5,"longitude":127.0,...}
      final parts = locationData.split(',');
      if (parts.length >= 3) {
        final workerId = parts[0].split(':')[1].replaceAll('"', '');
        final latitude = double.parse(parts[1].split(':')[1]);
        final longitude = double.parse(parts[2].split(':')[1]);

        add(LocationUpdated(
          latitude: latitude,
          longitude: longitude,
          workerId: workerId,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      print('Error parsing location data: $e');
    }
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) async {
    try {
      // Update or add worker location
      final existingIndex = _currentLocations
          .indexWhere((loc) => loc.workerId == event.workerId);

      final newLocation = WorkerLocation(
        workerId: event.workerId,
        workerName: event.workerId,
        latitude: event.latitude,
        longitude: event.longitude,
        equipmentId: event.equipmentId,
        lastUpdate: event.timestamp,
        isOnline: true,
      );

      if (existingIndex != -1) {
        _currentLocations[existingIndex] = newLocation;
      } else {
        _currentLocations.add(newLocation);
      }

      emit(LocationLoaded(workerLocations: _currentLocations));
    } catch (error) {
      emit(LocationFailure(message: error.toString()));
    }
  }

  Future<void> _onLocationUnsubscribed(
    LocationUnsubscribed event,
    Emitter<LocationState> emit,
  ) async {
    try {
      _stompClient?.deactivate();
      _currentLocations.clear();
      emit(const LocationInitial());
    } catch (error) {
      emit(LocationFailure(message: error.toString()));
    }
  }

  @override
  Future<void> close() {
    if (_stompClient?.connected ?? false) {
      _stompClient?.deactivate();
    }
    return super.close();
  }
}
