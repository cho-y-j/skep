import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  static final List<_EquipmentLocation> _mockEquipments = [
    _EquipmentLocation(
      id: 'eq1',
      vehicleNumber: '서울 가 1234',
      equipmentType: '크레인',
      operatorName: '김철수',
      latitude: 37.5665,
      longitude: 126.9780,
      status: 'working',
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    _EquipmentLocation(
      id: 'eq2',
      vehicleNumber: '경기 나 5678',
      equipmentType: '굴삭기',
      operatorName: '이영희',
      latitude: 37.5512,
      longitude: 127.0345,
      status: 'working',
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    _EquipmentLocation(
      id: 'eq3',
      vehicleNumber: '서울 다 9012',
      equipmentType: '덤프트럭',
      operatorName: '박민수',
      latitude: 37.4979,
      longitude: 127.0276,
      status: 'standby',
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    _EquipmentLocation(
      id: 'eq4',
      vehicleNumber: '경기 라 3456',
      equipmentType: '크레인',
      operatorName: '최지은',
      latitude: 37.3947,
      longitude: 127.1113,
      status: 'offline',
      lastUpdate: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    _EquipmentLocation(
      id: 'eq5',
      vehicleNumber: '서울 마 7890',
      equipmentType: '지게차',
      operatorName: '정대호',
      latitude: 37.5133,
      longitude: 126.9020,
      status: 'working',
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  List<_EquipmentLocation> get _filteredEquipments {
    return _mockEquipments.where((eq) {
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
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnEquipment(_EquipmentLocation eq) {
    setState(() {
      _selectedEquipmentId = eq.id;
    });
    _mapController.move(LatLng(eq.latitude, eq.longitude), 15.0);
  }

  void _requestLocation() {
    setState(() {
      _lastRequestTime = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '위치 갱신 완료: ${_formatTime(DateTime.now())}'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
                    _mockEquipments.where((e) => e.status == 'working').length),
                _buildStatusChip('대기', const Color(0xFFD97706),
                    _mockEquipments.where((e) => e.status == 'standby').length),
                _buildStatusChip('오프라인', const Color(0xFFDC2626),
                    _mockEquipments.where((e) => e.status == 'offline').length),
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
