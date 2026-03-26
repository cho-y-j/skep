import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/utils/date_formatter.dart';
import 'package:skep_app/core/utils/location_utils.dart';
import 'package:skep_app/core/widgets/app_button.dart';
import 'package:skep_app/core/widgets/app_card.dart';
import 'package:skep_app/core/widgets/status_badge.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_bloc.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_event.dart';
import 'package:skep_app/features/dispatch/bloc/dispatch_state.dart';

class WorkRecordScreen extends StatefulWidget {
  const WorkRecordScreen({Key? key}) : super(key: key);

  @override
  State<WorkRecordScreen> createState() => _WorkRecordScreenState();
}

class _WorkRecordScreenState extends State<WorkRecordScreen> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  Position? _currentPosition;
  bool _isNFCAvailable = false;
  String? _scannedNFCData;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkNFCAvailability();
    await _requestLocationPermission();
    context.read<DispatchBloc>().add(
      const DispatchWorkRecordsRequested(),
    );
  }

  Future<void> _checkNFCAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    setState(() => _isNFCAvailable = isAvailable);
  }

  Future<void> _requestLocationPermission() async {
    final permission = await LocationUtils.requestLocationPermission();
    if (permission) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationUtils.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _scanNFC() async {
    if (!_isNFCAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC is not available on this device'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final ndef = Ndef.from(tag);
          final ndefMessage = await ndef?.read();
          if (ndefMessage == null) return;
          final payload = ndefMessage.records.first.payload;
          final nfcData = String.fromCharCodes(payload);

          setState(() => _scannedNFCData = nfcData);
          context.read<DispatchBloc>().add(
            DispatchNFCScanned(nfcData: nfcData),
          );

          await NfcManager.instance.stopSession();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('NFC Scanned: $nfcData'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NFC error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startWorkTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
  }

  void _stopWorkTimer() {
    _timer?.cancel();
  }

  void _handleCheckIn(WorkRecord record) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<DispatchBloc>().add(
      DispatchWorkRecordCreated(
        equipmentId: record.equipmentId,
        workerId: record.workerId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
    );
  }

  void _handleStartWork(String workRecordId) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<DispatchBloc>().add(
      DispatchWorkStarted(
        workRecordId: workRecordId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
    );

    _startWorkTimer();
  }

  void _handleEndWork(String workRecordId) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _stopWorkTimer();

    context.read<DispatchBloc>().add(
      DispatchWorkEnded(
        workRecordId: workRecordId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Record'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (_isNFCAvailable)
            IconButton(
              icon: const Icon(Icons.nfc),
              onPressed: _scanNFC,
              tooltip: 'Scan NFC',
            ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<DispatchBloc, DispatchState>(
          listener: (context, state) {
            if (state is DispatchFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentPosition != null)
                  AppCard(
                    backgroundColor: AppColors.primaryLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          LocationUtils.formatCoordinates(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (_elapsedTime != Duration.zero)
                  AppCard(
                    backgroundColor: AppColors.primaryLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Elapsed Time',
                          style: AppTextStyles.labelLarge,
                        ),
                        Text(
                          DateFormatter.formatDuration(_elapsedTime),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Work Records',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 12),
                BlocBuilder<DispatchBloc, DispatchState>(
                  builder: (context, state) {
                    if (state is DispatchLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is DispatchWorkRecordsLoaded) {
                      if (state.workRecords.isEmpty) {
                        return Center(
                          child: Text(
                            'No work records',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (final record in state.workRecords)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.equipmentName,
                                                style: AppTextStyles.titleMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                record.workerName,
                                                style:
                                                    AppTextStyles.bodySmall
                                                        .copyWith(
                                                  color: AppColors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusBadge(
                                          label: record.status,
                                          status: record.status == 'CHECKED_IN'
                                              ? StatusType.pending
                                              : record.status == 'IN_PROGRESS'
                                                  ? StatusType.active
                                                  : StatusType.completed,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Check-in: ${DateFormatter.formatDateTime(record.checkinTime)}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.grey,
                                      ),
                                    ),
                                    if (record.startTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Start: ${DateFormatter.formatDateTime(record.startTime!)}',
                                        style:
                                            AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                    if (record.endTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'End: ${DateFormatter.formatDateTime(record.endTime!)}',
                                        style:
                                            AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    if (record.status == 'CHECKED_IN')
                                      AppButton(
                                        label: 'Start Work',
                                        onPressed: () =>
                                            _handleStartWork(record.id),
                                        width: double.infinity,
                                      )
                                    else if (record.status == 'IN_PROGRESS')
                                      AppButton(
                                        label: 'End Work',
                                        onPressed: () =>
                                            _handleEndWork(record.id),
                                        width: double.infinity,
                                        backgroundColor:
                                            AppColors.statusCompleted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    }

                    if (state is DispatchFailure) {
                      return Center(
                        child: Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
