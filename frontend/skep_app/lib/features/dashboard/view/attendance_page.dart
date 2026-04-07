import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendanceRecord {
  final String name;
  final String equipment;
  final DateTime? checkIn;
  final DateTime? workStart;
  final DateTime? workEnd;
  final String gpsCoord;

  const _AttendanceRecord({
    required this.name,
    required this.equipment,
    this.checkIn,
    this.workStart,
    this.workEnd,
    required this.gpsCoord,
  });

  String get totalWorkTime {
    if (workStart == null || workEnd == null) return '-';
    final diff = workEnd!.difference(workStart!);
    return '${diff.inHours}시간 ${diff.inMinutes % 60}분';
  }

  String get timeCategory {
    if (checkIn == null) return '-';
    final hour = checkIn!.hour;
    if (hour >= 21 || hour < 5) return '철야';
    if (hour >= 5 && hour < 7) return '조출';
    if (hour >= 7 && hour < 17) return '주간';
    if (hour >= 17 && hour < 19) return '연장';
    if (hour >= 19 && hour < 21) return '야간';
    return '-';
  }

  Color get timeCategoryColor {
    switch (timeCategory) {
      case '조출': return const Color(0xFF2196F3);
      case '주간': return const Color(0xFF16A34A);
      case '연장': return const Color(0xFFD97706);
      case '야간': return const Color(0xFF7C3AED);
      case '철야': return const Color(0xFFDC2626);
      default: return const Color(0xFF94A3B8);
    }
  }

  String get status {
    if (checkIn == null) return '미출근';
    final now = DateTime.now();
    final scheduledStart = DateTime(now.year, now.month, now.day, 7, 0);
    if (checkIn!.isAfter(scheduledStart.add(const Duration(minutes: 10)))) return '지각';
    return '출근';
  }

  Color get statusColor {
    switch (status) {
      case '출근': return const Color(0xFF16A34A);
      case '지각': return const Color(0xFFD97706);
      case '미출근': return const Color(0xFFDC2626);
      default: return const Color(0xFF94A3B8);
    }
  }
}

class _AttendancePageState extends State<AttendancePage> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _apiRecords = [];

  // 검색 & 필터 & 정렬
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '전체';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendance());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final response = await dioClient.get<dynamic>(
        ApiEndpoints.dailyRosters,
        queryParameters: {'date': dateStr},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _apiRecords = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _apiRecords = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _apiRecords = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _apiRecords = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clockIn() async {
    // Show dialog to select roster and worker before clocking in
    String? selectedRosterId;
    String? selectedWorkerId;
    String selectedWorkerType = 'DRIVER';

    if (_apiRecords.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출근할 배치 정보가 없습니다. 먼저 일일 배치를 확인하세요.'), backgroundColor: Color(0xFFD97706)),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('출근 기록'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: '배치 선택',
                        border: OutlineInputBorder(),
                      ),
                      items: _apiRecords.map((r) {
                        final id = r['id']?.toString() ?? '';
                        final label = '${r['workerName'] ?? r['operatorName'] ?? r['name'] ?? '-'} - ${r['equipmentName'] ?? r['equipment'] ?? '-'}';
                        return DropdownMenuItem<String>(value: id, child: Text(label));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedRosterId = val;
                          // Auto-fill worker info from selected roster
                          final roster = _apiRecords.firstWhere(
                            (r) => r['id']?.toString() == val,
                            orElse: () => <String, dynamic>{},
                          );
                          selectedWorkerId = roster['workerId']?.toString() ?? roster['operatorId']?.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedWorkerType,
                      decoration: const InputDecoration(
                        labelText: '작업자 유형',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'DRIVER', child: Text('운전원')),
                        DropdownMenuItem(value: 'GUIDE', child: Text('유도원')),
                        DropdownMenuItem(value: 'WORKER', child: Text('작업자')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedWorkerType = val ?? 'DRIVER'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedRosterId == null) return;
                    Navigator.of(ctx).pop({
                      'rosterId': selectedRosterId!,
                      'workerId': selectedWorkerId ?? '',
                      'workerType': selectedWorkerType,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('출근'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        ApiEndpoints.clockIn,
        data: {
          'dailyRosterId': result['rosterId'],
          'workerId': result['workerId'],
          'workerType': result['workerType'],
          'gpsLat': 0.0,
          'gpsLng': 0.0,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출근이 기록되었습니다.'), backgroundColor: Color(0xFF16A34A)),
        );
        _loadAttendance();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출근 기록 실패: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  List<_AttendanceRecord> get _records {
    // If API returned data, convert it
    if (_apiRecords.isNotEmpty) {
      return _apiRecords.map((r) {
        return _AttendanceRecord(
          name: (r['name'] ?? r['workerName'] ?? r['operatorName'] ?? '-').toString(),
          equipment: (r['equipment'] ?? r['equipmentName'] ?? '-').toString(),
          checkIn: _parseDateTime(r['checkIn'] ?? r['clockInTime']),
          workStart: _parseDateTime(r['workStart'] ?? r['startTime']),
          workEnd: _parseDateTime(r['workEnd'] ?? r['endTime']),
          gpsCoord: (r['gpsCoord'] ?? r['location'] ?? '-').toString(),
        );
      }).toList();
    }
    // Fallback to hardcoded data
    final d = _selectedDate;
    return [
      _AttendanceRecord(name: '김철수', equipment: '25톤 크레인 (서울 가 1234)', checkIn: DateTime(d.year, d.month, d.day, 6, 45), workStart: DateTime(d.year, d.month, d.day, 7, 0), workEnd: DateTime(d.year, d.month, d.day, 17, 30), gpsCoord: '37.5665, 126.9780'),
      _AttendanceRecord(name: '이영희', equipment: '50톤 크레인 (경기 나 5678)', checkIn: DateTime(d.year, d.month, d.day, 5, 50), workStart: DateTime(d.year, d.month, d.day, 6, 0), workEnd: DateTime(d.year, d.month, d.day, 17, 0), gpsCoord: '37.5512, 127.0345'),
      _AttendanceRecord(name: '박민수', equipment: '굴삭기 (서울 다 9012)', checkIn: DateTime(d.year, d.month, d.day, 7, 25), workStart: DateTime(d.year, d.month, d.day, 7, 30), workEnd: DateTime(d.year, d.month, d.day, 19, 0), gpsCoord: '37.4979, 127.0276'),
      _AttendanceRecord(name: '최지은', equipment: '덤프트럭 (경기 라 3456)', checkIn: DateTime(d.year, d.month, d.day, 19, 30), workStart: DateTime(d.year, d.month, d.day, 20, 0), workEnd: null, gpsCoord: '37.3947, 127.1113'),
      _AttendanceRecord(name: '정대호', equipment: '지게차 (서울 마 7890)', checkIn: null, workStart: null, workEnd: null, gpsCoord: '-'),
      _AttendanceRecord(name: '강기사', equipment: '25톤 크레인 (경기 바 2345)', checkIn: DateTime(d.year, d.month, d.day, 21, 30), workStart: DateTime(d.year, d.month, d.day, 22, 0), workEnd: null, gpsCoord: '37.4020, 126.9530'),
    ];
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  List<_AttendanceRecord> get _filteredRecords {
    var list = _records;

    if (_statusFilter != '전체') {
      list = list.where((r) => r.status == _statusFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((r) => r.name.toLowerCase().contains(query) || r.equipment.toLowerCase().contains(query)).toList();
    }

    if (_sortColumnIndex != null) {
      list = List.from(list);
      list.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0: result = a.name.compareTo(b.name); break;
          case 1: result = a.equipment.compareTo(b.equipment); break;
          case 5: result = a.totalWorkTime.compareTo(b.totalWorkTime); break;
          case 7: result = a.status.compareTo(b.status); break;
          default: result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    return list;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final allRecords = _records;
    final filtered = _filteredRecords;
    final checkedIn = allRecords.where((r) => r.status == '출근').length;
    final late = allRecords.where((r) => r.status == '지각').length;
    final absent = allRecords.where((r) => r.status == '미출근').length;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Text(DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.chevron_left, size: 24), onPressed: () { setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))); _loadAttendance(); }),
                IconButton(icon: const Icon(Icons.chevron_right, size: 24), onPressed: () { setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))); _loadAttendance(); }),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadAttendance();
                    }
                  },
                  child: const Text('날짜 선택', style: TextStyle(fontSize: 13)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _clockIn,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('출근'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadAttendance,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('새로고침'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 출근 현황 카드
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 3 ? 2.5 : 4,
                  children: [
                    _buildSummaryCard('출근', '$checkedIn명', Icons.check_circle, const Color(0xFF16A34A)),
                    _buildSummaryCard('미출근', '$absent명', Icons.cancel, const Color(0xFFDC2626)),
                    _buildSummaryCard('지각', '$late명', Icons.access_time, const Color(0xFFD97706)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // 시간대 범례
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegendItem('조출 (05-07)', const Color(0xFF2196F3)),
                  _buildLegendItem('주간 (07-17)', const Color(0xFF16A34A)),
                  _buildLegendItem('연장 (17-19)', const Color(0xFFD97706)),
                  _buildLegendItem('야간 (19-21:30)', const Color(0xFF7C3AED)),
                  _buildLegendItem('철야 (21-05)', const Color(0xFFDC2626)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 검색 & 필터
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '이름, 장비로 검색...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['전체', '출근', '지각', '미출근'].map((label) {
                        final isSelected = _statusFilter == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _statusFilter = label),
                            selectedColor: const Color(0xFF2196F3).withOpacity(0.15),
                            checkmarkColor: const Color(0xFF2196F3),
                            labelStyle: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF64748B)),
                            side: BorderSide(color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
            // 결과 카운트
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('총 ${filtered.length}건', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ),
            // 작업자 목록
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  columnSpacing: 20,
                  columns: [
                    DataColumn(label: const Text('이름'), onSort: _onSort),
                    DataColumn(label: const Text('장비'), onSort: _onSort),
                    const DataColumn(label: Text('출근시간')),
                    const DataColumn(label: Text('작업시작')),
                    const DataColumn(label: Text('작업종료')),
                    DataColumn(label: const Text('총작업시간'), onSort: _onSort),
                    const DataColumn(label: Text('시간대구분')),
                    DataColumn(label: const Text('상태'), onSort: _onSort),
                    const DataColumn(label: Text('GPS')),
                  ],
                  rows: filtered.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(r.equipment, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_formatTime(r.checkIn))),
                      DataCell(Text(_formatTime(r.workStart))),
                      DataCell(Text(_formatTime(r.workEnd))),
                      DataCell(Text(r.totalWorkTime)),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: r.timeCategoryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(r.timeCategory, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.timeCategoryColor)),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: r.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(r.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: r.statusColor)),
                      )),
                      DataCell(
                        r.gpsCoord == '-'
                            ? const Text('-', style: TextStyle(color: Color(0xFF94A3B8)))
                            : Tooltip(message: r.gpsCoord, child: const Icon(Icons.location_on, size: 16, color: Color(0xFF2196F3))),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            ], // end of _isLoading else
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }
}
