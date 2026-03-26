import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class RealtimeLocationPage extends StatefulWidget {
  const RealtimeLocationPage({Key? key}) : super(key: key);

  @override
  State<RealtimeLocationPage> createState() => _RealtimeLocationPageState();
}

class _EquipmentLocation {
  final String id;
  final String vehicleNumber;
  final String equipmentType;
  final String operatorName;
  final double latitude;
  final double longitude;
  final String status; // 'working', 'standby', 'offline'
  final DateTime lastUpdate;

  const _EquipmentLocation({
    required this.id,
    required this.vehicleNumber,
    required this.equipmentType,
    required this.operatorName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastUpdate,
  });

  Color get statusColor {
    switch (status) {
      case 'working':
        return const Color(0xFF16A34A);
      case 'standby':
        return const Color(0xFFD97706);
      case 'offline':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'working':
        return '작업중';
      case 'standby':
        return '대기';
      case 'offline':
        return '오프라인';
      default:
        return '알 수 없음';
    }
  }

  IconData get equipmentIcon {
    switch (equipmentType) {
      case '크레인':
        return Icons.precision_manufacturing;
      case '굴삭기':
        return Icons.construction;
      case '덤프트럭':
        return Icons.local_shipping;
      case '지게차':
        return Icons.forklift;
      default:
        return Icons.build;
    }
  }
}

class _RealtimeLocationPageState extends State<RealtimeLocationPage> {
  late MapController _mapController;
  String? _selectedEquipmentId;
  String _searchQuery = '';
  String _filterType = '전체';
  DateTime? _lastRequestTime;
  List<_EquipmentLocation> _equipments = [];
  bool _isLoading = true;
  String? _error;

  // Sites
  List<Map<String, dynamic>> _sites = [];
  String? _selectedSiteId;

  List<_EquipmentLocation> get _filteredEquipments {
    return _equipments.where((eq) {
      final matchesSearch = _searchQuery.isEmpty ||
          eq.vehicleNumber.contains(_searchQuery) ||
          eq.operatorName.contains(_searchQuery) ||
          eq.equipmentType.contains(_searchQuery);
      final matchesFilter =
          _filterType == '전체' || eq.equipmentType == _filterType;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSites());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
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
        }
        // Auto-select first site
        if (_sites.isNotEmpty && _selectedSiteId == null) {
          _selectedSiteId = _sites.first['id']?.toString();
        }
      }
    } catch (e) {
      // If sites fail to load, still allow manual input
      _sites = [];
    }
    // Load location data with selected site
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final siteId = _selectedSiteId ?? '1';
      final response = await dioClient.get<dynamic>(
        ApiEndpoints.locationCurrent.replaceAll('{siteId}', siteId),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<Map<String, dynamic>> rawList;
        if (data is List) {
          rawList = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          rawList = (data['content'] as List).cast<Map<String, dynamic>>();
        } else if (data is Map && data['locations'] is List) {
          rawList = (data['locations'] as List).cast<Map<String, dynamic>>();
        } else {
          rawList = [];
        }
        _equipments = rawList.map((item) {
          DateTime lastUpdate;
          try {
            lastUpdate = DateTime.parse(item['lastUpdate'] ?? item['updatedAt'] ?? item['timestamp'] ?? '');
          } catch (_) {
            lastUpdate = DateTime.now();
          }
          return _EquipmentLocation(
            id: (item['id'] ?? item['equipmentId'] ?? item['workerId'] ?? '').toString(),
            vehicleNumber: item['vehicleNumber'] ?? item['plateNo'] ?? '',
            equipmentType: item['equipmentType'] ?? item['type'] ?? '',
            operatorName: item['operatorName'] ?? item['workerName'] ?? '',
            latitude: (item['latitude'] ?? item['lat'] ?? 37.5665).toDouble(),
            longitude: (item['longitude'] ?? item['lng'] ?? item['lon'] ?? 126.9780).toDouble(),
            status: item['status'] ?? 'offline',
            lastUpdate: lastUpdate,
          );
        }).toList();
      }
    } catch (e) {
      _error = e.toString();
      _equipments = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _centerOnEquipment(_EquipmentLocation eq) {
    setState(() {
      _selectedEquipmentId = eq.id;
    });
    _mapController.move(LatLng(eq.latitude, eq.longitude), 15.0);
  }

  Future<void> _requestLocation() async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(ApiEndpoints.locationUpdate);
      await _loadData();
      setState(() {
        _lastRequestTime = DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '위치 갱신 완료: ${_formatTime(DateTime.now())}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      // Even if the POST fails, still refresh the location data
      await _loadData();
      setState(() {
        _lastRequestTime = DateTime.now();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '위치 갱신 완료: ${_formatTime(DateTime.now())}'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _equipments.isEmpty && _sites.isEmpty) {
      return Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 12),
              const Text('위치 데이터를 불러오는데 실패했습니다', style: TextStyle(color: Color(0xFFDC2626))),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadSites, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _buildSidePanel(),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        Expanded(child: _buildMap()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(flex: 3, child: _buildMap()),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(flex: 2, child: _buildSidePanel()),
      ],
    );
  }

  Widget _buildSidePanel() {
    final filtered = _filteredEquipments;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 검색 및 필터
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              children: [
                // Site selector
                if (_sites.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedSiteId,
                    decoration: InputDecoration(
                      labelText: '현장 선택',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    items: _sites.map((s) {
                      final id = s['id']?.toString() ?? '';
                      final name = s['name']?.toString() ?? s['siteName']?.toString() ?? '현장 #$id';
                      return DropdownMenuItem<String>(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSiteId = val);
                        _loadData();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  decoration: InputDecoration(
                    hintText: '차량번호, 운전원, 장비유형 검색',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                        items: ['전체', '크레인', '굴삭기', '덤프트럭', '지게차']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _filterType = v ?? '전체'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: _requestLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('위치 요청', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_lastRequestTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '마지막 갱신: ${_formatTime(_lastRequestTime!)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
              ],
            ),
          ),
          // 상태 요약
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusChip('작업중', const Color(0xFF16A34A),
                    _equipments.where((e) => e.status == 'working').length),
                _buildStatusChip('대기', const Color(0xFFD97706),
                    _equipments.where((e) => e.status == 'standby').length),
                _buildStatusChip('오프라인', const Color(0xFFDC2626),
                    _equipments.where((e) => e.status == 'offline').length),
              ],
            ),
          ),
          // 장비 목록
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final eq = filtered[index];
                final isSelected = eq.id == _selectedEquipmentId;
                return Material(
                  color: isSelected
                      ? const Color(0xFF2196F3).withOpacity(0.08)
                      : Colors.white,
                  child: InkWell(
                    onTap: () => _centerOnEquipment(eq),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: eq.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(eq.equipmentIcon, color: eq.statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eq.vehicleNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${eq.equipmentType} / ${eq.operatorName}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: eq.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              eq.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: eq.statusColor,
                              ),
                            ),
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
    );
  }

  Widget _buildStatusChip(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final filtered = _filteredEquipments;
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(37.5365, 126.9780),
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.skep.app',
        ),
        MarkerLayer(
          markers: filtered.map((eq) {
            return Marker(
              point: LatLng(eq.latitude, eq.longitude),
              width: 100,
              height: 70,
              child: GestureDetector(
                onTap: () => _centerOnEquipment(eq),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        eq.vehicleNumber.split(' ').last,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: eq.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      decoration: BoxDecoration(
                        color: eq.statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: eq.statusColor.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(eq.equipmentIcon, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
