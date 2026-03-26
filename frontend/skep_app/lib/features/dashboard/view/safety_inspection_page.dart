import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class SafetyInspectionPage extends StatefulWidget {
  const SafetyInspectionPage({Key? key}) : super(key: key);

  @override
  State<SafetyInspectionPage> createState() => _SafetyInspectionPageState();
}

class _InspectionItem {
  final int number;
  final String name;
  final String method;
  String? result; // 'pass', 'fail'
  String remarks;
  DateTime? timestamp;
  bool photoTaken;

  _InspectionItem({
    required this.number,
    required this.name,
    required this.method,
    this.result,
    this.remarks = '',
    this.timestamp,
    this.photoTaken = false,
  });

  bool get isCompleted => result != null && photoTaken;
}

class _SafetyInspectionPageState extends State<SafetyInspectionPage> {
  String? _selectedEquipment;
  bool _inspectionStarted = false;
  bool _inspectionSubmitted = false;
  int _currentItemIndex = 0;
  final _inspectorCommentController = TextEditingController();
  bool _showHistory = false;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _equipmentList = [];
  List<Map<String, dynamic>> _historyList = [];
  String? _currentInspectionId;

  late List<_InspectionItem> _items;

  @override
  void initState() {
    super.initState();
    _initItems();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();

      final results = await Future.wait([
        dioClient.get<dynamic>(ApiEndpoints.equipments).catchError((_) => null),
        dioClient.get<dynamic>(ApiEndpoints.safetyInspections).catchError((_) => null),
      ]);

      // Equipment list for dropdown
      final eqData = results[0]?.data;
      if (eqData is List) {
        _equipmentList = eqData.cast<Map<String, dynamic>>();
      } else if (eqData is Map && eqData['content'] is List) {
        _equipmentList = (eqData['content'] as List).cast<Map<String, dynamic>>();
      } else if (eqData is Map && eqData['data'] is List) {
        _equipmentList = (eqData['data'] as List).cast<Map<String, dynamic>>();
      } else {
        _equipmentList = [];
      }

      // Inspection history
      final inspData = results[1]?.data;
      if (inspData is List) {
        _historyList = inspData.cast<Map<String, dynamic>>();
      } else if (inspData is Map && inspData['content'] is List) {
        _historyList = (inspData['content'] as List).cast<Map<String, dynamic>>();
      } else if (inspData is Map && inspData['data'] is List) {
        _historyList = (inspData['data'] as List).cast<Map<String, dynamic>>();
      } else {
        _historyList = [];
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getEquipmentLabel(Map<String, dynamic> eq) {
    final name = eq['name']?.toString() ?? eq['equipmentName']?.toString() ?? '';
    final plate = eq['plateNumber']?.toString() ?? eq['plateNo']?.toString() ?? '';
    if (name.isNotEmpty && plate.isNotEmpty) return '$name ($plate)';
    if (name.isNotEmpty) return name;
    if (plate.isNotEmpty) return plate;
    return eq['id']?.toString() ?? '-';
  }

  String _getEquipmentId(Map<String, dynamic> eq) {
    return eq['id']?.toString() ?? '';
  }

  void _initItems() {
    _items = [
      _InspectionItem(number: 1, name: '과부하방지장치', method: '정격하중 초과 시 자동 정지 여부를 확인합니다.'),
      _InspectionItem(number: 2, name: '비상정지장치', method: '비상정지 버튼 작동 여부를 확인합니다.'),
      _InspectionItem(number: 3, name: '비상하강장치', method: '비상 시 하강 기능 정상 작동을 확인합니다.'),
      _InspectionItem(number: 4, name: '아웃트리거', method: '아웃트리거 전개/수축 및 고정 상태를 확인합니다.'),
      _InspectionItem(number: 5, name: '와이어로프', method: '와이어로프 마모, 꼬임, 절단 여부를 육안 점검합니다.'),
      _InspectionItem(number: 6, name: '선회장치/작업대', method: '선회장치 회전 및 작업대 고정 상태를 확인합니다.'),
      _InspectionItem(number: 7, name: '외관상태', method: '차체 외관의 파손, 변형, 부식 여부를 점검합니다.'),
      _InspectionItem(number: 8, name: '브레이크/클러치', method: '브레이크 및 클러치 작동 상태를 확인합니다.'),
      _InspectionItem(number: 9, name: '모니터', method: '계기판 및 모니터 표시 상태를 확인합니다.'),
      _InspectionItem(number: 10, name: '타이어', method: '타이어 마모, 공기압, 균열 여부를 점검합니다.'),
      _InspectionItem(number: 11, name: '모멘트감지장치', method: '모멘트 리미터 정상 작동을 확인합니다.'),
    ];
  }

  @override
  void dispose() {
    _inspectorCommentController.dispose();
    super.dispose();
  }

  int get _completedCount => _items.where((i) => i.isCompleted).length;

  Future<void> _startInspection() async {
    if (_selectedEquipment == null) return;
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.post<dynamic>(
        '${ApiEndpoints.safetyInspections}/start',
        data: {'equipmentId': _selectedEquipment},
      );
      if (response.data != null && response.data is Map) {
        _currentInspectionId = response.data['id']?.toString();
      }
      setState(() => _inspectionStarted = true);
    } catch (e) {
      // If API fails, still allow local inspection flow
      setState(() => _inspectionStarted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 기록 실패 (오프라인 모드): $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _recordItem(int index, String result) async {
    setState(() {
      _items[index].result = result;
      _items[index].timestamp = DateTime.now();
      if (_items[index].isCompleted && index == _currentItemIndex && _currentItemIndex < 10) {
        _currentItemIndex = index + 1;
      }
    });

    if (_currentInspectionId != null) {
      try {
        final dioClient = context.read<DioClient>();
        await dioClient.post<dynamic>(
          '${ApiEndpoints.safetyInspections}/$_currentInspectionId/record-item',
          data: {
            'itemNumber': _items[index].number,
            'itemName': _items[index].name,
            'result': result,
            'remarks': _items[index].remarks,
          },
        );
      } catch (_) {
        // Silent fail - local state already updated
      }
    }
  }

  Future<void> _submitInspection() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('안전점검 제출 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장비: ${_getSelectedEquipmentLabel()}'),
            Text('적합: ${_items.where((i) => i.result == 'pass').length}건'),
            Text('부적합: ${_items.where((i) => i.result == 'fail').length}건'),
            const SizedBox(height: 8),
            const Text('제출 후 수정이 불가합니다. 제출하시겠습니까?',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Complete via API
              if (_currentInspectionId != null) {
                try {
                  final dioClient = this.context.read<DioClient>();
                  await dioClient.post<dynamic>(
                    '${ApiEndpoints.safetyInspections}/$_currentInspectionId/complete',
                    data: {
                      'comment': _inspectorCommentController.text,
                      'passCount': _items.where((i) => i.result == 'pass').length,
                      'failCount': _items.where((i) => i.result == 'fail').length,
                    },
                  );
                } catch (_) {
                  // Silent fail
                }
              }
              setState(() => _inspectionSubmitted = true);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('안전점검이 제출되었습니다.'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  String _getSelectedEquipmentLabel() {
    if (_selectedEquipment == null) return '-';
    final match = _equipmentList.where((eq) => _getEquipmentId(eq) == _selectedEquipment);
    if (match.isNotEmpty) return _getEquipmentLabel(match.first);
    return _selectedEquipment!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _equipmentList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                _buildToggle('안전점검', !_showHistory, () => setState(() => _showHistory = false)),
                                _buildToggle('점검 이력', _showHistory, () => setState(() => _showHistory = true)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: '새로고침',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_showHistory) _buildHistoryView() else _buildInspectionView(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionView() {
    if (_inspectionSubmitted) {
      return _buildSubmittedView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 장비 선택
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('장비 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedEquipment,
                decoration: InputDecoration(
                  hintText: '점검할 장비를 선택하세요',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                items: _equipmentList
                    .map((eq) => DropdownMenuItem(
                          value: _getEquipmentId(eq),
                          child: Text(_getEquipmentLabel(eq)),
                        ))
                    .toList(),
                onChanged: _inspectionStarted
                    ? null
                    : (v) => setState(() => _selectedEquipment = v),
              ),
              if (_selectedEquipment != null && !_inspectionStarted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startInspection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('점검 시작', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_inspectionStarted) ...[
          const SizedBox(height: 20),
          // 진행 바
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '진행 상황: $_completedCount / 11 완료',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    Text(
                      '${(_completedCount / 11 * 100).round()}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2196F3)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedCount / 11,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _completedCount == 11 ? const Color(0xFF16A34A) : const Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 점검 항목 목록
          ...List.generate(11, (index) => _buildInspectionItemCard(index)),
          // 최종 제출 (11개 모두 완료시)
          if (_completedCount == 11) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('점검자 의견', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inspectorCommentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: '종합 의견을 입력하세요',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitInspection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('점검 완료 및 제출', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildInspectionItemCard(int index) {
    final item = _items[index];
    final isCurrentOrDone = index <= _currentItemIndex;
    final isLocked = index > _currentItemIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedOpacity(
        opacity: isLocked ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: item.isCompleted
                ? Border.all(color: const Color(0xFF16A34A).withOpacity(0.3))
                : (index == _currentItemIndex
                    ? Border.all(color: const Color(0xFF2196F3).withOpacity(0.3), width: 2)
                    : null),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? const Color(0xFF16A34A)
                          : (isCurrentOrDone ? const Color(0xFF2196F3) : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: item.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                              '${item.number}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrentOrDone ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          item.method,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (item.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.result == 'pass'
                            ? const Color(0xFF16A34A).withOpacity(0.1)
                            : const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.result == 'pass' ? '적합' : '부적합',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.result == 'pass' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  if (isLocked)
                    const Icon(Icons.lock, size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
              if (isCurrentOrDone && !item.isCompleted && !isLocked) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                // 사진 촬영
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => item.photoTaken = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('사진 촬영 시뮬레이션 완료'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: Icon(
                        item.photoTaken ? Icons.check_circle : Icons.camera_alt,
                        size: 16,
                      ),
                      label: Text(
                        item.photoTaken ? '사진 촬영 완료' : '사진 촬영 (필수)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.photoTaken ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (item.timestamp != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('HH:mm:ss').format(item.timestamp!),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // 판정 버튼
                Row(
                  children: [
                    const Text('판정:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: item.photoTaken
                          ? () => _recordItem(index, 'pass')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.result == 'pass' ? const Color(0xFF16A34A) : Colors.white,
                        foregroundColor: item.result == 'pass' ? Colors.white : const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text('적합', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: item.photoTaken
                          ? () => _recordItem(index, 'fail')
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.result == 'fail' ? const Color(0xFFDC2626) : Colors.white,
                        foregroundColor: item.result == 'fail' ? Colors.white : const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text('부적합', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 특이사항
                TextField(
                  decoration: InputDecoration(
                    hintText: '특이사항 (선택)',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) => item.remarks = v,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 16),
          const Text('안전점검 완료 (잠금)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
          const SizedBox(height: 8),
          Text('장비: ${_getSelectedEquipmentLabel()}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            '적합: ${_items.where((i) => i.result == 'pass').length}건 / 부적합: ${_items.where((i) => i.result == 'fail').length}건',
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _inspectionSubmitted = false;
                _inspectionStarted = false;
                _selectedEquipment = null;
                _currentItemIndex = 0;
                _currentInspectionId = null;
                _inspectorCommentController.clear();
                _initItems();
              });
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('새 점검 시작'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_historyList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: const Center(child: Text('점검 이력이 없습니다.', style: TextStyle(color: Color(0xFF94A3B8)))),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          columns: const [
            DataColumn(label: Text('날짜')),
            DataColumn(label: Text('장비')),
            DataColumn(label: Text('점검자')),
            DataColumn(label: Text('적합')),
            DataColumn(label: Text('부적합')),
            DataColumn(label: Text('상태')),
          ],
          rows: _historyList.map((h) {
            final date = h['inspectionDate'] ?? h['createdAt'] ?? h['date'];
            String dateStr;
            try {
              dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(date.toString()));
            } catch (_) {
              dateStr = date?.toString() ?? '-';
            }
            final equipment = h['equipmentName']?.toString() ?? h['equipment']?.toString() ?? '-';
            final inspector = h['inspectorName']?.toString() ?? h['inspector']?.toString() ?? '-';
            final passCount = h['passCount'] ?? h['pass_count'] ?? 0;
            final failCount = h['failCount'] ?? h['fail_count'] ?? 0;
            final status = h['status']?.toString() ?? '-';

            return DataRow(cells: [
              DataCell(Text(dateStr)),
              DataCell(Text(equipment)),
              DataCell(Text(inspector)),
              DataCell(Text('$passCount건', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600))),
              DataCell(Text('$failCount건', style: TextStyle(
                color: (failCount is int && failCount > 0) ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (status == 'COMPLETED' || status == 'completed' || status == '완료')
                        ? const Color(0xFF16A34A).withOpacity(0.1)
                        : const Color(0xFFD97706).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (status == 'COMPLETED' || status == 'completed') ? '완료' : status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (status == 'COMPLETED' || status == 'completed' || status == '완료')
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
