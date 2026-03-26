import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/utils/location_utils.dart';
import 'package:skep_app/core/widgets/app_button.dart';
import 'package:skep_app/core/widgets/app_card.dart';
import 'package:skep_app/core/widgets/app_text_field.dart';
import 'package:skep_app/features/inspection/bloc/inspection_bloc.dart';
import 'package:skep_app/features/inspection/bloc/inspection_event.dart';
import 'package:skep_app/features/inspection/bloc/inspection_state.dart';

class SafetyInspectionScreen extends StatefulWidget {
  final String inspectionId;

  const SafetyInspectionScreen({
    Key? key,
    required this.inspectionId,
  }) : super(key: key);

  @override
  State<SafetyInspectionScreen> createState() =>
      _SafetyInspectionScreenState();
}

class _SafetyInspectionScreenState extends State<SafetyInspectionScreen> {
  late TextEditingController _notesController;
  Position? _currentPosition;
  List<String> _selectedPhotos = [];
  bool _isNFCAvailable = false;
  bool _nfcScanned = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _checkNFCAvailability();
    await _requestLocationPermission();
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
      _showError('Failed to get location: $e');
    }
  }

  Future<void> _scanNFC() async {
    if (!_isNFCAvailable) {
      _showError('NFC is not available on this device');
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

          setState(() => _nfcScanned = true);

          context.read<InspectionBloc>().add(
            InspectionStarted(
              inspectionId: widget.inspectionId,
              latitude: _currentPosition?.latitude ?? 0,
              longitude: _currentPosition?.longitude ?? 0,
            ),
          );

          await NfcManager.instance.stopSession();

          if (mounted) {
            _showSuccess('NFC Scanned - Inspection Started');
          }
        },
      );
    } catch (e) {
      _showError('NFC error: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _selectedPhotos.add(image.path);
        });
        _showSuccess('Photo added');
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleItemCheck(InspectionItem item, bool passed) {
    context.read<InspectionBloc>().add(
      InspectionItemChecked(
        inspectionId: widget.inspectionId,
        itemId: item.id,
        passed: passed,
        notes: _notesController.text,
        photoUrls: _selectedPhotos,
      ),
    );

    _notesController.clear();
    _selectedPhotos.clear();
  }

  void _handleInspectionComplete() {
    if (_currentPosition == null) {
      _showError('Location not available');
      return;
    }

    context.read<InspectionBloc>().add(
      InspectionCompleted(
        inspectionId: widget.inspectionId,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Inspection'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (_isNFCAvailable && !_nfcScanned)
            IconButton(
              icon: const Icon(Icons.nfc),
              onPressed: _scanNFC,
              tooltip: 'Scan NFC to start',
            ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<InspectionBloc, InspectionState>(
          listener: (context, state) {
            if (state is InspectionCompletedState) {
              _showSuccess('Inspection completed');
              Navigator.pop(context);
            } else if (state is InspectionFailure) {
              _showError(state.message);
            }
          },
          child: BlocBuilder<InspectionBloc, InspectionState>(
            builder: (context, state) {
              if (!_nfcScanned && _isNFCAvailable) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.nfc,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Scan NFC Tag to Start',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please scan the NFC tag to begin the inspection',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Scan NFC',
                        onPressed: _scanNFC,
                      ),
                    ],
                  ),
                );
              }

              if (state is InspectionLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is InspectionInProgress) {
                if (state.currentItemIndex >= state.items.length) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'All Items Checked',
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Complete Inspection',
                          onPressed: _handleInspectionComplete,
                        ),
                      ],
                    ),
                  );
                }

                final currentItem =
                    state.items[state.currentItemIndex];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (state.currentItemIndex + 1) /
                            state.items.length,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Item ${currentItem.itemNumber} of ${currentItem.totalItems}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentItem.title,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentItem.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Photos',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 12),
                            if (_selectedPhotos.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedPhotos.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.file(
                                              File(_selectedPhotos[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedPhotos
                                                      .removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: AppColors.error,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: AppColors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Take Photo',
                              onPressed: _pickImage,
                              width: double.infinity,
                              backgroundColor: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: 'Notes',
                        hint: 'Add any notes for this item',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Pass',
                              onPressed: () =>
                                  _handleItemCheck(currentItem, true),
                              backgroundColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              label: 'Fail',
                              onPressed: () =>
                                  _handleItemCheck(currentItem, false),
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              if (state is InspectionFailure) {
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
        ),
      ),
    );
  }
}
