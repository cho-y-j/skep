import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class SettlementDetailPage extends StatefulWidget {
  const SettlementDetailPage({Key? key}) : super(key: key);

  @override
  State<SettlementDetailPage> createState() => _SettlementDetailPageState();
}

class _SettlementDetailPageState extends State<SettlementDetailPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedBP = '';
  final _numberFormat = NumberFormat('#,###');
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _apiSettlement;

  List<String> _bpList = [];
  bool _bpListLoaded = false;

  // 단가 (can be overridden by API)
  int _dayRate = 850000;
  int _dayOTRate = 120000;
  int _nightRate = 1100000;
  int _nightOTRate = 150000;
  int _dutyRate = 30000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBpListAndSettlement());
  }

  Future<void> _loadBpListAndSettlement() async {
    if (!_bpListLoaded) {
      try {
        final dioClient = context.read<DioClient>();
        final response = await dioClient.get<dynamic>(
          ApiEndpoints.companiesByType.replaceAll('{type}', 'BP_COMPANY'),
        );
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          List<dynamic> items = [];
          if (data is List) {
            items = data;
          } else if (data is Map && data['companies'] is List) {
            items = data['companies'] as List;
          } else if (data is Map && data['content'] is List) {
            items = data['content'] as List;
          }
          _bpList = items.map((bp) {
            final m = bp as Map<String, dynamic>;
            return (m['name'] ?? m['companyName'] ?? '').toString();
          }).where((name) => name.isNotEmpty).toList();
        }
      } catch (_) {
        // Fallback
        _bpList = ['강남 건설 BP', '송파 건설 BP', '성남 건설 BP'];
      }
      if (_bpList.isEmpty) {
        _bpList = ['강남 건설 BP', '송파 건설 BP', '성남 건설 BP'];
      }
      _bpListLoaded = true;
      if (_selectedBP.isEmpty && _bpList.isNotEmpty) {
        _selectedBP = _bpList.first;
      }
      if (mounted) setState(() {});
    }
    await _loadSettlement();
  }

  Future<void> _loadSettlement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final monthStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      final response = await dioClient.get<dynamic>(
        ApiEndpoints.settlements,
        queryParameters: {
          'month': monthStr,
          'bp': _selectedBP,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _apiSettlement = data;
          // Update rates from API if available
          if (data['dayRate'] != null) _dayRate = (data['dayRate'] as num).toInt();
          if (data['dayOTRate'] != null) _dayOTRate = (data['dayOTRate'] as num).toInt();
          if (data['nightRate'] != null) _nightRate = (data['nightRate'] as num).toInt();
          if (data['nightOTRate'] != null) _nightOTRate = (data['nightOTRate'] as num).toInt();
          if (data['dutyRate'] != null) _dutyRate = (data['dutyRate'] as num).toInt();
        }
      }
    } catch (e) {
      _error = e.toString();
      _apiSettlement = null;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<_DailySettlement> get _data {
    // Use API data if available
    if (_apiSettlement != null && _apiSettlement!['dailyData'] is List) {
      return (_apiSettlement!['dailyData'] as List).map((item) {
        final m = item as Map<String, dynamic>;
        return _DailySettlement(
          day: (m['day'] as num?)?.toInt() ?? 0,
          isWeekend: m['isWeekend'] == true,
          dayWork: (m['dayWork'] as num?)?.toInt() ?? 0,
          dayOT: (m['dayOT'] as num?)?.toInt() ?? 0,
          nightWork: (m['nightWork'] as num?)?.toInt() ?? 0,
          nightOT: (m['nightOT'] as num?)?.toInt() ?? 0,
          duty: (m['duty'] as num?)?.toInt() ?? 0,
          rest: (m['rest'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    }
    // Fallback to generated mock data
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    return List.generate(daysInMonth, (i) {
      final day = i + 1;
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isWeekend = date.weekday > 5;
      if (isWeekend) {
        return _DailySettlement(day: day, isWeekend: true);
      }
      return _DailySettlement(
        day: day,
        isWeekend: false,
        dayWork: day % 5 != 0 ? 1 : 0,
        dayOT: day % 3 == 0 ? 1 : 0,
        nightWork: day % 10 == 0 ? 1 : 0,
        nightOT: day % 15 == 0 ? 1 : 0,
        duty: day % 5 != 0 ? 1 : 0,
        rest: day % 5 == 0 ? 1 : 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final totalDay = data.fold<int>(0, (sum, d) => sum + d.dayWork);
    final totalDayOT = data.fold<int>(0, (sum, d) => sum + d.dayOT);
    final totalNight = data.fold<int>(0, (sum, d) => sum + d.nightWork);
    final totalNightOT = data.fold<int>(0, (sum, d) => sum + d.nightOT);
    final totalDuty = data.fold<int>(0, (sum, d) => sum + d.duty);

    final supplyAmount = (totalDay * _dayRate) +
        (totalDayOT * _dayOTRate) +
        (totalNight * _nightRate) +
        (totalNightOT * _nightOTRate) +
        (totalDuty * _dutyRate);
    final tax = (supplyAmount * 0.1).round();
    final totalAmount = supplyAmount + tax;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 필터
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 월 선택
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                        });
                        _loadBpListAndSettlement();
                      },
                    ),
                    Text(
                      DateFormat('yyyy년 MM월').format(_selectedMonth),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                        });
                        _loadBpListAndSettlement();
                      },
                    ),
                  ],
                ),
                // BP 선택
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _bpList.contains(_selectedBP) ? _selectedBP : (_bpList.isNotEmpty ? _bpList.first : null),
                    decoration: InputDecoration(
                      labelText: 'BP사',
                      labelStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                    items: _bpList.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedBP = v ?? _selectedBP);
                      _loadBpListAndSettlement();
                    },
                  ),
                ),
                // PDF / 이메일
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF 다운로드 시뮬레이션'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF 다운로드', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이메일 발송 시뮬레이션'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.email, size: 16),
                  label: const Text('이메일 발송', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _apiSettlement == null)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 12),
                      const Text('데이터를 불러오는데 실패했습니다'),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadSettlement, child: const Text('다시 시도')),
                    ],
                  ),
                ),
              ),
            // 거래명세서 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '거 래 명 세 서',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('yyyy년 MM월').format(_selectedMonth)} | $_selectedBP',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            // 요약 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final items = [
                    _buildAmountCard('공급가액', _numberFormat.format(supplyAmount), '원', const Color(0xFF2196F3)),
                    _buildAmountCard('세액 (10%)', _numberFormat.format(tax), '원', const Color(0xFFD97706)),
                    _buildAmountCard('합계', _numberFormat.format(totalAmount), '원', const Color(0xFF16A34A)),
                  ];
                  if (isWide) {
                    return Row(
                      children: items
                          .expand((w) => [Expanded(child: w), if (w != items.last) const SizedBox(width: 16)])
                          .toList(),
                    );
                  }
                  return Column(
                    children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w)).toList(),
                  );
                },
              ),
            ),
            // 일별 상세 테이블
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  columnSpacing: 18,
                  columns: const [
                    DataColumn(label: Text('날짜')),
                    DataColumn(label: Text('주간'), numeric: true),
                    DataColumn(label: Text('주간OT'), numeric: true),
                    DataColumn(label: Text('철야/월대'), numeric: true),
                    DataColumn(label: Text('철야OT'), numeric: true),
                    DataColumn(label: Text('출무'), numeric: true),
                    DataColumn(label: Text('휴무'), numeric: true),
                  ],
                  rows: [
                    ...data.map((d) {
                      return DataRow(
                        color: d.isWeekend
                            ? WidgetStateProperty.all(const Color(0xFFFEF2F2))
                            : null,
                        cells: [
                          DataCell(Text(
                            '${d.day}일',
                            style: TextStyle(
                              color: d.isWeekend ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                          DataCell(Text(d.isWeekend ? '-' : '${d.dayWork}')),
                          DataCell(Text(d.isWeekend ? '-' : '${d.dayOT}')),
                          DataCell(Text(d.isWeekend ? '-' : '${d.nightWork}')),
                          DataCell(Text(d.isWeekend ? '-' : '${d.nightOT}')),
                          DataCell(Text(d.isWeekend ? '-' : '${d.duty}')),
                          DataCell(Text(d.isWeekend ? '1' : '${d.rest}')),
                        ],
                      );
                    }),
                    // 합계 행
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFF0F9FF)),
                      cells: [
                        const DataCell(Text('합계', style: TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('$totalDay', style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('$totalDayOT', style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('$totalNight', style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('$totalNightOT', style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text('$totalDuty', style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text(
                          '${data.fold<int>(0, (s, d) => s + d.rest)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 단가표
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('단가표', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  _buildRateRow('주간 단가', _dayRate),
                  _buildRateRow('주간OT 단가', _dayOTRate),
                  _buildRateRow('철야/월대 단가', _nightRate),
                  _buildRateRow('철야OT 단가', _nightOTRate),
                  _buildRateRow('출무 수당', _dutyRate),
                  const Divider(height: 20),
                  _buildRateRow('금월 공급가액', supplyAmount, isBold: true),
                  _buildRateRow('세액 (10%)', tax, isBold: true),
                  _buildRateRow('합계 금액', totalAmount, isBold: true, color: const Color(0xFF16A34A)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit, style: TextStyle(fontSize: 12, color: color)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, int amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            '${_numberFormat.format(amount)}원',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySettlement {
  final int day;
  final bool isWeekend;
  final int dayWork;
  final int dayOT;
  final int nightWork;
  final int nightOT;
  final int duty;
  final int rest;

  const _DailySettlement({
    required this.day,
    this.isWeekend = false,
    this.dayWork = 0,
    this.dayOT = 0,
    this.nightWork = 0,
    this.nightOT = 0,
    this.duty = 0,
    this.rest = 0,
  });
}
