import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class _InspectionHistory {
  final DateTime date;
  final String equipment;
  final String inspector;
  final int passCount;
  final int failCount;
  final String status;

  const _InspectionHistory({
    required this.date,
    required this.equipment,
    required this.inspector,
    required this.passCount,
    required this.failCount,
    required this.status,
  });
}

class _SafetyInspectionPageState extends State<SafetyInspectionPage> {
  String? _selectedEquipment;
  bool _inspectionStarted = false;
  bool _inspectionSubmitted = false;
  int _currentItemIndex = 0;
  final _inspectorCommentController = TextEditingController();
  bool _showHistory = false;

  final List<String> _equipmentList = [
    '25톤 크레인 (서울 가 1234)',
    '50톤 크레인 (경기 나 5678)',
    '굴삭기 (서울 다 9012)',
    '덤프트럭 (경기 라 3456)',
    '지게차 (서울 마 7890)',
  ];

  late List<_InspectionItem> _items;

  final List<_InspectionHistory> _history = [
    _InspectionHistory(
      date: DateTime.now().subtract(const Duration(days: 1)),
      equipment: '25톤 크레인 (서울 가 1234)',
      inspector: '박안전',
      passCount: 10,
      failCount: 1,
      status: '완료',
    ),
    _InspectionHistory(
      date: DateTime.now().subtract(const Duration(days: 2)),
      equipment: '50톤 크레인 (경기 나 5678)',
      inspector: '박안전',
      passCount: 11,
      failCount: 0,
      status: '완료',
    ),
    _InspectionHistory(
      date: DateTime.now().subtract(const Duration(days: 3)),
      equipment: '굴삭기 (서울 다 9012)',
      inspector: '김점검',
      passCount: 9,
      failCount: 2,
      status: '완료',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initItems();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                    onPressed: () => setState(() => _inspectionStarted = true),
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
                          ? () => _judgeItem(index, 'pass')
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
                          ? () => _judgeItem(index, 'fail')
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

  void _judgeItem(int index, String result) {
    setState(() {
      _items[index].result = result;
      _items[index].timestamp = DateTime.now();
      if (_items[index].isCompleted && index == _currentItemIndex && _currentItemIndex < 10) {
        _currentItemIndex = index + 1;
      }
    });
  }

  void _submitInspection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('안전점검 제출 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장비: $_selectedEquipment'),
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
            onPressed: () {
              Navigator.pop(context);
              setState(() => _inspectionSubmitted = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('안전점검이 제출되었습니다.'), backgroundColor: Color(0xFF16A34A)),
              );
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
          Text('장비: $_selectedEquipment', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
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
                _inspectorCommentController.clear();
                _initItems();
              });
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
          rows: _history.map((h) {
            return DataRow(cells: [
              DataCell(Text(DateFormat('yyyy-MM-dd').format(h.date))),
              DataCell(Text(h.equipment)),
              DataCell(Text(h.inspector)),
              DataCell(Text('${h.passCount}건', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600))),
              DataCell(Text('${h.failCount}건', style: TextStyle(
                color: h.failCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
              ))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
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
