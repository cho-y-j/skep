import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/utils/date_formatter.dart';
import 'package:skep_app/features/location/bloc/location_bloc.dart';
import 'package:skep_app/features/location/bloc/location_event.dart';
import 'package:skep_app/features/location/bloc/location_state.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({Key? key}) : super(key: key);

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    context.read<LocationBloc>().add(const LocationSubscribed());
  }

  @override
  void dispose() {
    _mapController.dispose();
    context.read<LocationBloc>().add(const LocationUnsubscribed());
    super.dispose();
  }

  void _fitMapToMarkers(List<WorkerLocation> locations) {
    if (locations.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(
      locations.map((loc) => LatLng(loc.latitude, loc.longitude)).toList(),
    );

    _mapController.fitBounds(bounds, options: const FitBoundsOptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, state) {
          if (state is LocationLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is LocationLoaded) {
            if (state.workerLocations.isEmpty) {
              return Center(
                child: Text(
                  'No workers online',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              );
            }

            // Auto-fit map to all markers on first load
            Future.microtask(() =>
                _fitMapToMarkers(state.workerLocations));

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      state.workerLocations.first.latitude,
                      state.workerLocations.first.longitude,
                    ),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: state.workerLocations
                          .map(
                            (location) => Marker(
                              point: LatLng(
                                location.latitude,
                                location.longitude,
                              ),
                              width: 80,
                              height: 80,
                              child: GestureDetector(
                                onTap: () {
                                  _showWorkerDetails(location);
                                },
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: location.isOnline
                                            ? AppColors.success
                                            : AppColors.grey,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.white,
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        location.workerName
                                            .split(' ')
                                            .first,
                                        style:
                                            AppTextStyles.labelSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () =>
                        _fitMapToMarkers(state.workerLocations),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Online Workers: ${state.workerLocations.length}',
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.workerLocations.length,
                            itemBuilder: (context, index) {
                              final worker =
                                  state.workerLocations[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      _showWorkerDetails(worker),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          worker.workerName,
                                          style: AppTextStyles
                                              .labelSmall,
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  BoxDecoration(
                                                color: worker
                                                        .isOnline
                                                    ? AppColors
                                                        .success
                                                    : AppColors
                                                        .grey,
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              worker.isOnline
                                                  ? 'Online'
                                                  : 'Offline',
                                              style: AppTextStyles
                                                  .labelSmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (state is LocationFailure) {
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
    );
  }

  void _showWorkerDetails(WorkerLocation worker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker.workerName,
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color:
                        worker.isOnline ? AppColors.success : AppColors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  worker.isOnline ? 'Online' : 'Offline',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Location: ${worker.latitude.toStringAsFixed(4)}, ${worker.longitude.toStringAsFixed(4)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
              ),
            ),
            if (worker.equipmentName != null) ...[
              const SizedBox(height: 12),
              Text(
                'Equipment: ${worker.equipmentName}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Last Update: ${DateFormatter.formatDateTime(worker.lastUpdate)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
