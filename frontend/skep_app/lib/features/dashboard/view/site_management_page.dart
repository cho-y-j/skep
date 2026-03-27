import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class SiteManagementPage extends StatefulWidget {
  const SiteManagementPage({Key? key}) : super(key: key);

  @override
  State<SiteManagementPage> createState() => _SiteManagementPageState();
}

class _SiteManagementPageState extends State<SiteManagementPage> {
  List<Map<String, dynamic>> _sites = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedSiteIndex;
  bool _showMapInDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.sites);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _sites = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _sites = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _sites = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _sites = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'INACTIVE':
        return const Color(0xFF94A3B8);
      case 'COMPLETED':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return '활성';
      case 'INACTIVE':
        return '비활성';
      case 'COMPLETED':
        return '완료';
      default:
        return status;
    }
  }

  String _boundaryTypeLabel(String? type) {
    switch (type?.toUpperCase()) {
      case 'CIRCLE':
        return '원형';
      case 'POLYGON':
        return '폴리곤';
      default:
        return type ?? '-';
    }
  }

  /// Parse polygon coordinates from various formats
  List<LatLng> _parsePolygonCoords(dynamic coords) {
    if (coords == null) return [];
    try {
      List<dynamic> coordList;
      if (coords is String) {
        coordList = json.decode(coords) as List<dynamic>;
      } else if (coords is List) {
        coordList = coords;
      } else {
        return [];
      }
      return coordList.map((c) {
        if (c is List && c.length >= 2) {
          return LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble());
        }
        if (c is Map) {
          final lat = (c['lat'] ?? c['latitude'] as num?)?.toDouble() ?? 0;
          final lng = (c['lng'] ?? c['longitude'] as num?)?.toDouble() ?? 0;
          return LatLng(lat, lng);
        }
        return LatLng(0, 0);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate circle points for overlay
  List<LatLng> _generateCirclePoints(LatLng center, double radiusMeters, {int segments = 64}) {
    final points = <LatLng>[];
    const distance = Distance();
    for (int i = 0; i <= segments; i++) {
      final bearing = (360.0 / segments) * i;
      final point = distance.offset(center, radiusMeters, bearing);
      points.add(point);
    }
    return points;
  }

  void _showCreateDialog() {
    _showMapInDialog = false;
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final radiusController = TextEditingController(text: '500');
    final coordsController = TextEditingController();
    String boundaryType = 'CIRCLE';
    String? selectedBpCompanyId;
    List<Map<String, dynamic>> bpCompanies = [];
    bool loadingBp = true;

    // Map state for CIRCLE
    LatLng? circleCenter;
    // Map state for POLYGON
    List<LatLng> polygonPoints = [];

    final mapController = MapController();

    showDialog(
      context: context,
      builder: (ctx) {
        // Load BP companies
        context.read<DioClient>().get<dynamic>(
          ApiEndpoints.companiesByType.replaceFirst('{type}', 'BP_COMPANY'),
        ).then((res) {
          if (res.data is List) {
            bpCompanies = (res.data as List).cast<Map<String, dynamic>>();
          } else if (res.data is Map && res.data['content'] is List) {
            bpCompanies = (res.data['content'] as List).cast<Map<String, dynamic>>();
          }
          loadingBp = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        }).catchError((_) {
          loadingBp = false;
          if (ctx.mounted) (ctx as Element).markNeedsBuild();
        });

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('현장 등록'),
              content: SizedBox(
                width: 600,
                height: 700,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '현장명 *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: '주소',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      loadingBp
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: selectedBpCompanyId,
                              decoration: const InputDecoration(
                                labelText: 'BP사 선택',
                                border: OutlineInputBorder(),
                              ),
                              items: bpCompanies.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['id']?.toString(),
                                  child: Text(c['name']?.toString() ?? c['companyName']?.toString() ?? '-'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() => selectedBpCompanyId = val);
                              },
                            ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: boundaryType,
                        decoration: const InputDecoration(
                          labelText: '범위 유형',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CIRCLE', child: Text('원형 (CIRCLE)')),
                          DropdownMenuItem(value: 'POLYGON', child: Text('폴리곤 (POLYGON)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              boundaryType = val;
                              // Reset map state on type change
                              circleCenter = null;
                              polygonPoints = [];
                              latController.clear();
                              lngController.clear();
                              coordsController.clear();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Interactive map
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(37.5665, 126.9780),
                                initialZoom: 12,
                                onTap: (tapPosition, latLng) {
                                  setDialogState(() {
                                    if (boundaryType == 'CIRCLE') {
                                      circleCenter = latLng;
                                      latController.text = latLng.latitude.toStringAsFixed(6);
                                      lngController.text = latLng.longitude.toStringAsFixed(6);
                                    } else {
                                      polygonPoints.add(latLng);
                                      // Update coords text field
                                      final coordsList = polygonPoints
                                          .map((p) => [
                                                double.parse(p.latitude.toStringAsFixed(6)),
                                                double.parse(p.longitude.toStringAsFixed(6)),
                                              ])
                                          .toList();
                                      coordsController.text = json.encode(coordsList);
                                    }
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.skep.app',
                                ),
                                // Circle overlay
                                if (boundaryType == 'CIRCLE' && circleCenter != null) ...[
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: circleCenter!,
                                        width: 24,
                                        height: 24,
                                        child: const Icon(Icons.location_on, color: Colors.red, size: 24),
                                      ),
                                    ],
                                  ),
                                  if (radiusController.text.isNotEmpty &&
                                      (double.tryParse(radiusController.text) ?? 0) > 0)
                                    PolygonLayer(
                                      polygons: [
                                        Polygon(
                                          points: _generateCirclePoints(
                                            circleCenter!,
                                            double.parse(radiusController.text),
                                          ),
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderColor: AppColors.primary,
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                ],
                                // Polygon overlay
                                if (boundaryType == 'POLYGON' && polygonPoints.isNotEmpty) ...[
                                  MarkerLayer(
                                    markers: polygonPoints
                                        .map((p) => Marker(
                                              point: p,
                                              width: 16,
                                              height: 16,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                  if (polygonPoints.length >= 3)
                                    PolygonLayer(
                                      polygons: [
                                        Polygon(
                                          points: polygonPoints,
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderColor: AppColors.primary,
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                  if (polygonPoints.length >= 2)
                                    PolylineLayer(
                                      polylines: [
                                        Polyline(
                                          points: polygonPoints,
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                            // Map instruction overlay
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  boundaryType == 'CIRCLE'
                                      ? '지도를 탭하여 중심점 설정'
                                      : '지도를 탭하여 꼭짓점 추가 (${polygonPoints.length}개)',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                            // Undo button for polygon
                            if (boundaryType == 'POLYGON' && polygonPoints.isNotEmpty)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        polygonPoints.removeLast();
                                        final coordsList = polygonPoints
                                            .map((p) => [
                                                  double.parse(p.latitude.toStringAsFixed(6)),
                                                  double.parse(p.longitude.toStringAsFixed(6)),
                                                ])
                                            .toList();
                                        coordsController.text =
                                            polygonPoints.isEmpty ? '' : json.encode(coordsList);
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.undo, size: 18, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (boundaryType == 'CIRCLE') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latController,
                                decoration: const InputDecoration(
                                  labelText: '위도',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final lat = double.tryParse(v);
                                  final lng = double.tryParse(lngController.text);
                                  if (lat != null && lng != null) {
                                    setDialogState(() => circleCenter = LatLng(lat, lng));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: lngController,
                                decoration: const InputDecoration(
                                  labelText: '경도',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final lat = double.tryParse(latController.text);
                                  final lng = double.tryParse(v);
                                  if (lat != null && lng != null) {
                                    setDialogState(() => circleCenter = LatLng(lat, lng));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: radiusController,
                          decoration: const InputDecoration(
                            labelText: '반경 (m)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ] else ...[
                        TextField(
                          controller: coordsController,
                          decoration: const InputDecoration(
                            labelText: '좌표 (JSON)',
                            hintText: '[[lat,lng],[lat,lng],...]',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: '설명',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final body = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'address': addressController.text.trim(),
                      'boundaryType': boundaryType,
                      'description': descController.text.trim(),
                    };
                    if (selectedBpCompanyId != null) {
                      body['bpCompanyId'] = selectedBpCompanyId;
                    }
                    if (boundaryType == 'CIRCLE') {
                      if (latController.text.isNotEmpty) body['centerLat'] = double.tryParse(latController.text);
                      if (lngController.text.isNotEmpty) body['centerLng'] = double.tryParse(lngController.text);
                      if (radiusController.text.isNotEmpty) body['radiusMeters'] = int.tryParse(radiusController.text);
                    } else {
                      if (coordsController.text.isNotEmpty) body['boundaryCoordinates'] = coordsController.text.trim();
                    }
                    try {
                      final dioClient = context.read<DioClient>();
                      await dioClient.post<dynamic>(ApiEndpoints.sites, data: body);
                      if (mounted) Navigator.of(ctx).pop();
                      await _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('현장이 등록되었습니다'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('현장 등록 실패: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build a small map preview widget for a site
  Widget _buildSiteMapPreview(Map<String, dynamic> site) {
    final boundaryType = site['boundaryType']?.toString()?.toUpperCase();
    final lat = (site['latitude'] as num?)?.toDouble();
    final lng = (site['longitude'] as num?)?.toDouble();
    final radius = (site['radius'] as num?)?.toDouble();
    final coords = site['coordinates'];

    LatLng center = const LatLng(37.5665, 126.9780);
    double zoom = 14;
    List<Polygon> polygons = [];
    List<Marker> markers = [];

    if (boundaryType == 'CIRCLE' && lat != null && lng != null) {
      center = LatLng(lat, lng);
      markers.add(Marker(
        point: center,
        width: 20,
        height: 20,
        child: const Icon(Icons.location_on, color: Colors.red, size: 20),
      ));
      if (radius != null && radius > 0) {
        polygons.add(Polygon(
          points: _generateCirclePoints(center, radius),
          color: AppColors.primary.withOpacity(0.15),
          borderColor: AppColors.primary,
          borderStrokeWidth: 2,
        ));
        // Adjust zoom based on radius
        if (radius > 2000) {
          zoom = 11;
        } else if (radius > 500) {
          zoom = 13;
        } else {
          zoom = 15;
        }
      }
    } else if (boundaryType == 'POLYGON') {
      final points = _parsePolygonCoords(coords);
      if (points.isNotEmpty) {
        // Calculate center from polygon points
        double avgLat = 0, avgLng = 0;
        for (final p in points) {
          avgLat += p.latitude;
          avgLng += p.longitude;
        }
        center = LatLng(avgLat / points.length, avgLng / points.length);
        polygons.add(Polygon(
          points: points,
          color: AppColors.primary.withOpacity(0.15),
          borderColor: AppColors.primary,
          borderStrokeWidth: 2,
        ));
        for (final p in points) {
          markers.add(Marker(
            point: p,
            width: 10,
            height: 10,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ));
        }
      }
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.skep.app',
          ),
          if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현장 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('등록된 현장을 관리합니다.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.greyDark,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('현장 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('데이터를 불러오는데 실패했습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    if (_sites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.location_city_outlined, size: 56, color: Color(0xFFCBD5E1)),
              const SizedBox(height: 16),
              const Text('등록된 현장이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('총 ${_sites.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sites.length,
          itemBuilder: (context, index) {
            final s = _sites[index];
            final status = s['status']?.toString() ?? 'ACTIVE';
            final isExpanded = _expandedSiteIndex == index;

            return Column(
              children: [
                if (index == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 40),
                        Expanded(flex: 2, child: Text('현장명', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Expanded(flex: 2, child: Text('주소', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Expanded(flex: 1, child: Text('BP사', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Expanded(flex: 1, child: Text('범위유형', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Expanded(flex: 1, child: Text('상태', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                        Expanded(flex: 1, child: Text('생성일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                      ],
                    ),
                  ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedSiteIndex = isExpanded ? null : index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExpanded ? const Color(0xFFF0F9FF) : Colors.white,
                      border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['name']?.toString() ?? s['siteName']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            s['address']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            s['bpCompanyName']?.toString() ?? s['bpCompany']?['name']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _boundaryTypeLabel(s['boundaryType']?.toString()),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            _formatDate(s['createdAt'] ?? s['created_at']),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expanded map preview
                if (isExpanded)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            const Text('현장 위치', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const Spacer(),
                            if (s['boundaryType']?.toString().toUpperCase() == 'CIRCLE') ...[
                              Text(
                                '위도: ${s['latitude'] ?? '-'}  경도: ${s['longitude'] ?? '-'}  반경: ${s['radius'] ?? '-'}m',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSiteMapPreview(s),
                        if (s['description'] != null && s['description'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('설명: ${s['description']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
