import 'package:flutter/material.dart';
import 'package:skep_app/core/constants/app_colors.dart';

/// BP사 장비 매칭 요청 페이지
class MatchingRequestPage extends StatefulWidget {
  const MatchingRequestPage({Key? key}) : super(key: key);

  @override
  State<MatchingRequestPage> createState() => _MatchingRequestPageState();
}

class _MatchingRequestPageState extends State<MatchingRequestPage> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedEquipmentType;
  int _startHour = 9;
  int _endHour = 18;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _showResults = false;

  static const _darkText = Color(0xFF1E293B);
  static const _pageBg = Color(0xFFF8FAFC);
  static const _cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
  ];

  static const List<String> _equipmentTypes = [
    '타워크레인',
    '이동식크레인',
    '굴착기',
    '지게차',
    '고소작업차',
    '항타기',
    '콘크리트펌프카',
  ];

  final List<_MatchingResult> _mockResults = [
    _MatchingResult(
      status: _MatchStatus.available,
      plateNumber: '경기99사9489',
      spec: '45m 고소작업차',
      company: '(주)대성스카이크레인',
      operator: '김운전',
      licenseValid: true,
      docsStatus: '전체 유효',
      docsOk: true,
      inspectionStatus: '완료',
      inspectionOk: true,
      insuranceStatus: 'D-180',
      insuranceOk: true,
      dailyRate: 850000,
      otRate: 50000,
    ),
    _MatchingResult(
      status: _MatchStatus.available,
      plateNumber: '경기11가2222',
      spec: '50m 고소작업차',
      company: '(주)한라크레인',
      operator: '이기사',
      licenseValid: true,
      docsStatus: '전체 유효',
      docsOk: true,
      inspectionStatus: '완료',
      inspectionOk: true,
      insuranceStatus: 'D-90',
      insuranceOk: true,
      dailyRate: 920000,
      otRate: 55000,
    ),
    _MatchingResult(
      status: _MatchStatus.conditional,
      plateNumber: '서울12가3456',
      spec: '35m 고소작업차',
      company: '(주)센코어테크',
      operator: '박기사',
      licenseValid: true,
      docsStatus: '보험 D-7',
      docsOk: false,
      inspectionStatus: '완료',
      inspectionOk: true,
      insuranceStatus: 'D-7',
      insuranceOk: false,
      healthCheckWarning: 'D-15',
      dailyRate: 780000,
      otRate: 45000,
    ),
    _MatchingResult(
      status: _MatchStatus.conditional,
      plateNumber: '부산55나7890',
      spec: '40m 고소작업차',
      company: '(주)부산크레인',
      operator: '최운전',
      licenseValid: true,
      docsStatus: '안전교육 D-5',
      docsOk: false,
      inspectionStatus: '완료',
      inspectionOk: true,
      insuranceStatus: 'D-120',
      insuranceOk: true,
      dailyRate: 800000,
      otRate: 48000,
    ),
    _MatchingResult(
      status: _MatchStatus.unavailable,
      plateNumber: '인천34나5678',
      spec: '25m 고소작업차',
      company: '(주)한국크레인',
      unavailableReason: '해당일 이미 투입 중 (강남 현장 A)',
    ),
    _MatchingResult(
      status: _MatchStatus.unavailable,
      plateNumber: '대전77다1234',
      spec: '30m 고소작업차',
      company: '(주)중부장비',
      unavailableReason: '안전검사 미완료 (검사 예정일: 4/5)',
    ),
  ];

  final List<_RequestHistory> _mockHistory = [
    _RequestHistory(
      date: '2026-03-20',
      type: '이동식크레인',
      site: '용인 현장 B',
      status: '수락',
      supplier: '(주)한국크레인',
      responseDate: '2026-03-20',
    ),
    _RequestHistory(
      date: '2026-03-18',
      type: '고소작업차',
      site: '강남 현장 A',
      status: '견적발송',
      supplier: '(주)대성스카이크레인',
      responseDate: '2026-03-19',
    ),
    _RequestHistory(
      date: '2026-03-15',
      type: '굴착기',
      site: '수원 현장 C',
      status: '거절',
      supplier: '(주)센코어테크',
      responseDate: '2026-03-16',
    ),
    _RequestHistory(
      date: '2026-03-14',
      type: '타워크레인',
      site: '판교 현장 D',
      status: '요청중',
      supplier: '-',
      responseDate: '-',
    ),
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '장비 매칭',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '필요한 장비를 검색하고 즉시 매칭 결과를 확인하세요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            _buildRequestForm(),
            if (_showResults) ...[
              const SizedBox(height: 32),
              _buildMatchingResults(),
            ],
            const SizedBox(height: 32),
            _buildRequestHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '매칭 요청서',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEquipmentTypeField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTimeFields()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildLocationField()),
                      ],
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildEquipmentTypeField(),
                  const SizedBox(height: 16),
                  _buildTimeFields(),
                  const SizedBox(height: 16),
                  _buildLocationField(),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildNoteField(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showResults = true;
                });
              },
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                '매칭 검색',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '요청일자',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('ko', 'KR'),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: _darkText),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '장비 유형',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedEquipmentType,
              hint: const Text('장비 유형 선택', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              items: _equipmentTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (value) => setState(() => _selectedEquipmentType = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '작업시간',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _startHour,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                    items: List.generate(24, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 14)),
                      );
                    }),
                    onChanged: (v) => setState(() => _startHour = v!),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
            ),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _endHour,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                    items: List.generate(24, (i) {
                      return DropdownMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 14)),
                      );
                    }),
                    onChanged: (v) => setState(() => _endHour = v!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '현장위치',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: '예: 용인시 처인구 ○○현장',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추가 요청사항 (선택)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '추가 요청사항을 입력하세요',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingResults() {
    final available = _mockResults.where((r) => r.status == _MatchStatus.available).toList();
    final conditional = _mockResults.where((r) => r.status == _MatchStatus.conditional).toList();
    final unavailable = _mockResults.where((r) => r.status == _MatchStatus.unavailable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '매칭 결과',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_mockResults.length}건',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...available.map((r) => _buildResultCard(r)),
        ...conditional.map((r) => _buildResultCard(r)),
        ...unavailable.map((r) => _buildResultCard(r)),
      ],
    );
  }

  Widget _buildResultCard(_MatchingResult result) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (result.status) {
      case _MatchStatus.available:
        statusColor = const Color(0xFF16A34A);
        statusLabel = '매칭 가능';
        statusIcon = Icons.check_circle;
        break;
      case _MatchStatus.conditional:
        statusColor = const Color(0xFFD97706);
        statusLabel = '조건부 가능';
        statusIcon = Icons.warning_rounded;
        break;
      case _MatchStatus.unavailable:
        statusColor = const Color(0xFFDC2626);
        statusLabel = '불가';
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Equipment info
          Text(
            '${result.plateNumber}  |  ${result.spec}  |  ${result.company}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkText),
          ),
          if (result.status == _MatchStatus.unavailable) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '사유: ${result.unavailableReason}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
          if (result.status != _MatchStatus.unavailable) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '운전원: ${result.operator}',
                  style: const TextStyle(fontSize: 13, color: _darkText),
                ),
                const SizedBox(width: 4),
                Text(
                  '(면허 유효 ${result.licenseValid! ? '\u2705' : '\u274C'})',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Document status row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  '서류',
                  result.docsOk! ? result.docsStatus! : result.docsStatus!,
                  result.docsOk!,
                ),
                _buildStatusChip(
                  '안전검사',
                  result.inspectionStatus!,
                  result.inspectionOk!,
                ),
                _buildStatusChip(
                  result.insuranceOk! ? '보험' : (result.healthCheckWarning != null ? '건강검진' : '보험'),
                  result.insuranceOk! ? result.insuranceStatus! : (result.healthCheckWarning ?? result.insuranceStatus!),
                  result.insuranceOk! && result.healthCheckWarning == null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Pricing
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    '단가: 일대 ${_formatCurrency(result.dailyRate!)}원',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _darkText),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '/ O/T 시간당 ${_formatCurrency(result.otRate!)}원',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (result.status == _MatchStatus.available)
                  _buildActionButton('투입 요청', AppColors.primary, Icons.send, filled: true),
                _buildActionButton('견적 요청', const Color(0xFF7C3AED), Icons.request_quote_outlined),
                _buildActionButton('상세 보기', const Color(0xFF64748B), Icons.visibility_outlined),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, bool ok) {
    final color = ok ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final icon = ok ? Icons.check_circle : Icons.warning_rounded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, {bool filled = false}) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label 완료'), duration: const Duration(seconds: 1)),
          );
        },
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label 완료'), duration: const Duration(seconds: 1)),
        );
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write(',');
      result.write(str[i]);
    }
    return result.toString();
  }

  Widget _buildRequestHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                '요청 이력',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkText),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              headingTextStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _darkText,
              ),
              dataTextStyle: const TextStyle(fontSize: 13, color: _darkText),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('요청일')),
                DataColumn(label: Text('장비유형')),
                DataColumn(label: Text('현장')),
                DataColumn(label: Text('상태')),
                DataColumn(label: Text('공급사')),
                DataColumn(label: Text('응답일')),
              ],
              rows: _mockHistory.map((h) {
                return DataRow(cells: [
                  DataCell(Text(h.date)),
                  DataCell(Text(h.type)),
                  DataCell(Text(h.site)),
                  DataCell(_buildHistoryStatusBadge(h.status)),
                  DataCell(Text(h.supplier)),
                  DataCell(Text(h.responseDate)),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case '수락':
        bgColor = const Color(0xFF16A34A).withOpacity(0.1);
        textColor = const Color(0xFF16A34A);
        break;
      case '거절':
        bgColor = const Color(0xFFDC2626).withOpacity(0.1);
        textColor = const Color(0xFFDC2626);
        break;
      case '견적발송':
        bgColor = const Color(0xFF7C3AED).withOpacity(0.1);
        textColor = const Color(0xFF7C3AED);
        break;
      case '요청중':
      default:
        bgColor = const Color(0xFFD97706).withOpacity(0.1);
        textColor = const Color(0xFFD97706);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

enum _MatchStatus { available, conditional, unavailable }

class _MatchingResult {
  final _MatchStatus status;
  final String plateNumber;
  final String spec;
  final String company;
  final String? operator;
  final bool? licenseValid;
  final String? docsStatus;
  final bool? docsOk;
  final String? inspectionStatus;
  final bool? inspectionOk;
  final String? insuranceStatus;
  final bool? insuranceOk;
  final String? healthCheckWarning;
  final int? dailyRate;
  final int? otRate;
  final String? unavailableReason;

  const _MatchingResult({
    required this.status,
    required this.plateNumber,
    required this.spec,
    required this.company,
    this.operator,
    this.licenseValid,
    this.docsStatus,
    this.docsOk,
    this.inspectionStatus,
    this.inspectionOk,
    this.insuranceStatus,
    this.insuranceOk,
    this.healthCheckWarning,
    this.dailyRate,
    this.otRate,
    this.unavailableReason,
  });
}

class _RequestHistory {
  final String date;
  final String type;
  final String site;
  final String status;
  final String supplier;
  final String responseDate;

  const _RequestHistory({
    required this.date,
    required this.type,
    required this.site,
    required this.status,
    required this.supplier,
    required this.responseDate,
  });
}
