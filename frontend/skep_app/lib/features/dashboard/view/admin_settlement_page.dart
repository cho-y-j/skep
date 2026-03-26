import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminSettlementPage extends StatefulWidget {
  const AdminSettlementPage({Key? key}) : super(key: key);

  @override
  State<AdminSettlementPage> createState() => _AdminSettlementPageState();
}

class _AdminSettlementPageState extends State<AdminSettlementPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _settlements = [];
  bool _isLoading = true;
  String? _error;

  // Summary values
  num _totalAmount = 0;
  num _paidAmount = 0;
  num _unpaidAmount = 0;

  // Tab controller
  late TabController _tabController;

  // Calendar state
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(ApiEndpoints.settlements);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _settlements = data.cast<Map<String, dynamic>>();
        } else if (data is Map) {
          if (data['settlements'] is List) {
            _settlements = (data['settlements'] as List).cast<Map<String, dynamic>>();
          } else if (data['content'] is List) {
            _settlements = (data['content'] as List).cast<Map<String, dynamic>>();
          } else {
            _settlements = [];
          }
          // Extract summary data if available
          _totalAmount = data['totalAmount'] ?? data['total_amount'] ?? 0;
          _paidAmount = data['paidAmount'] ?? data['paid_amount'] ?? 0;
          _unpaidAmount = data['unpaidAmount'] ?? data['unpaid_amount'] ?? 0;
        }

        // If summary not provided at top level, compute from settlements
        if (_totalAmount == 0 && _settlements.isNotEmpty) {
          _totalAmount = 0;
          _paidAmount = 0;
          _unpaidAmount = 0;
          for (var s in _settlements) {
            final amount = (s['amount'] ?? s['totalAmount'] ?? s['total_amount'] ?? 0) as num;
            _totalAmount += amount;
            final status = s['status']?.toString() ?? s['paymentStatus']?.toString() ?? '';
            if (status == 'PAID' || status == '지급완료') {
              _paidAmount += amount;
            } else {
              _unpaidAmount += amount;
            }
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      _settlements = [];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatMoney(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0 && str[i] != '-') {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _getSupplierName(Map<String, dynamic> s) {
    return s['supplierName']?.toString() ?? s['supplier_name']?.toString() ?? s['companyName']?.toString() ?? '-';
  }

  String _getBpName(Map<String, dynamic> s) {
    return s['bpName']?.toString() ?? s['bp_name']?.toString() ?? s['clientName']?.toString() ?? '-';
  }

  String _getPaymentStatus(Map<String, dynamic> s) {
    final status = s['status']?.toString() ?? s['paymentStatus']?.toString() ?? '';
    switch (status) {
      case 'PAID': return '지급완료';
      case 'UNPAID': return '미지급';
      case 'PARTIAL': return '일부지급';
      case 'DRAFT': return '초안';
      case 'SENT': return '발송';
      default: return status.isNotEmpty ? status : '-';
    }
  }

  String _getRawStatus(Map<String, dynamic> s) {
    return s['status']?.toString() ?? s['paymentStatus']?.toString() ?? '';
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case '지급완료': return AppColors.success;
      case '미지급': return AppColors.error;
      case '일부지급': return AppColors.warning;
      case '초안': return AppColors.grey;
      case '발송': return AppColors.info;
      default: return AppColors.grey;
    }
  }

  num _getAmount(Map<String, dynamic> s) {
    return (s['amount'] ?? s['totalAmount'] ?? s['total_amount'] ?? 0) as num;
  }

  DateTime? _getSettlementDate(Map<String, dynamic> s) {
    final dateStr = s['date']?.toString() ??
        s['settlementDate']?.toString() ??
        s['settlement_date']?.toString() ??
        s['startDate']?.toString() ??
        s['start_date']?.toString() ??
        s['createdAt']?.toString() ??
        s['created_at']?.toString();
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
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
                    Text('정산', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '전체 정산 현황을 확인합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                    ),
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
            ],
          ),
          const SizedBox(height: 24),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                '데이터를 불러오는데 실패했습니다',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _loadData, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildSummaryCard(
                  '월간 총 거래액',
                  '${_formatMoney(_totalAmount)}원',
                  AppColors.primary,
                  Icons.account_balance_outlined,
                ),
                _buildSummaryCard(
                  '지급 완료',
                  '${_formatMoney(_paidAmount)}원',
                  AppColors.success,
                  Icons.check_circle_outline,
                ),
                _buildSummaryCard(
                  '미지급',
                  '${_formatMoney(_unpaidAmount)}원',
                  AppColors.error,
                  Icons.pending_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: '목록'),
                  Tab(text: '달력'),
                  Tab(text: '차트'),
                ],
                onTap: (_) => setState(() {}),
              ),
              const Divider(height: 1),
              _buildTabContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    // Use AnimatedBuilder with TabController to rebuild on tab change
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        switch (_tabController.index) {
          case 0:
            return _buildListTab();
          case 1:
            return _buildCalendarTab();
          case 2:
            return _buildChartTab();
          default:
            return _buildListTab();
        }
      },
    );
  }

  // ==================== Tab 1: List ====================
  Widget _buildListTab() {
    if (_settlements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                '정산 데이터가 없습니다',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('공급사')),
          DataColumn(label: Text('BP사')),
          DataColumn(label: Text('거래액'), numeric: true),
          DataColumn(label: Text('정산기간')),
          DataColumn(label: Text('결제상태')),
        ],
        rows: _settlements.map((s) {
          final amount = _getAmount(s);
          final paymentStatus = _getPaymentStatus(s);
          final period = s['period']?.toString() ?? s['settlementPeriod']?.toString() ?? _formatDate(s['startDate'] ?? s['start_date']);
          return DataRow(cells: [
            DataCell(Text(_getSupplierName(s))),
            DataCell(Text(_getBpName(s))),
            DataCell(Text('${_formatMoney(amount)}원')),
            DataCell(Text(period)),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _paymentStatusColor(paymentStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                paymentStatus,
                style: TextStyle(
                  color: _paymentStatusColor(paymentStatus),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  // ==================== Tab 2: Calendar ====================
  Widget _buildCalendarTab() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;

    // Build daily totals map
    final Map<int, num> dailyTotals = {};
    for (var s in _settlements) {
      final dt = _getSettlementDate(s);
      if (dt != null && dt.year == year && dt.month == month) {
        final day = dt.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + _getAmount(s);
      }
    }

    // First day of month and total days
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday=1 ... Sunday=7; we want Mon as first column
    final startWeekday = firstDay.weekday; // 1=Mon

    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month - 1);
                  });
                },
              ),
              Text(
                '${year}년 ${month}월',
                style: AppTextStyles.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(year, month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Calendar grid
          Table(
            border: TableBorder.all(color: AppColors.border, width: 0.5),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: weekDays.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                )).toList(),
              ),
              // Day rows
              ..._buildCalendarRows(startWeekday, daysInMonth, dailyTotals),
            ],
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              const Text('정산 있음', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 16),
              Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              const Text('정산 없음', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildCalendarRows(int startWeekday, int daysInMonth, Map<int, num> dailyTotals) {
    final rows = <TableRow>[];
    int dayCounter = 1;
    // startWeekday: 1=Mon .. 7=Sun; offset = startWeekday - 1
    final offset = startWeekday - 1;

    // Calculate total weeks needed
    final totalCells = offset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    for (int row = 0; row < totalRows; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < offset || dayCounter > daysInMonth) {
          cells.add(Container(height: 60));
        } else {
          final day = dayCounter;
          final hasData = dailyTotals.containsKey(day);
          final amount = dailyTotals[day] ?? 0;
          cells.add(Container(
            height: 60,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasData ? AppColors.primary.withOpacity(0.08) : AppColors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: col == 6 ? AppColors.error : (col == 5 ? AppColors.info : const Color(0xFF1E293B)),
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatCompactMoney(amount),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ));
          dayCounter++;
        }
      }
      rows.add(TableRow(children: cells));
    }
    return rows;
  }

  String _formatCompactMoney(num amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}억';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    }
    return _formatMoney(amount);
  }

  // ==================== Tab 3: Charts ====================
  Widget _buildChartTab() {
    if (_settlements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.grey),
              const SizedBox(height: 12),
              Text('차트를 표시할 데이터가 없습니다',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar chart: monthly settlement amounts
          Text('월별 정산 금액', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildMonthlyBarChart(),
          ),
          const SizedBox(height: 32),
          // Pie chart: status distribution
          Text('상태별 비율', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _buildStatusPieChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    // Group settlements by month
    final Map<String, num> monthlyAmounts = {};
    for (var s in _settlements) {
      final dt = _getSettlementDate(s);
      if (dt != null) {
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        monthlyAmounts[key] = (monthlyAmounts[key] ?? 0) + _getAmount(s);
      } else {
        // Group under 'unknown'
        monthlyAmounts['기타'] = (monthlyAmounts['기타'] ?? 0) + _getAmount(s);
      }
    }

    if (monthlyAmounts.isEmpty) {
      // Fallback: show total as single bar
      monthlyAmounts['전체'] = _totalAmount;
    }

    final sortedKeys = monthlyAmounts.keys.toList()..sort();
    final maxVal = monthlyAmounts.values.fold<num>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal.toDouble() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final key = sortedKeys[group.x.toInt()];
              return BarTooltipItem(
                '$key\n${_formatMoney(rod.toY.toInt())}원',
                const TextStyle(color: AppColors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                final label = sortedKeys[idx];
                // Show just month part if it's YYYY-MM
                final display = label.length > 5 ? label.substring(5) + '월' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(display, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatCompactMoney(value.toInt()),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal.toDouble() / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedKeys.asMap().entries.map((entry) {
          final idx = entry.key;
          final key = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: monthlyAmounts[key]!.toDouble(),
                color: AppColors.primary,
                width: sortedKeys.length > 6 ? 16 : 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusPieChart() {
    // Count by status
    final Map<String, num> statusAmounts = {};
    for (var s in _settlements) {
      final raw = _getRawStatus(s);
      final label = _statusLabel(raw);
      statusAmounts[label] = (statusAmounts[label] ?? 0) + _getAmount(s);
    }

    if (statusAmounts.isEmpty) {
      return const Center(child: Text('데이터 없음'));
    }

    final colors = <String, Color>{
      '초안': AppColors.grey,
      '발송': AppColors.info,
      '지급완료': AppColors.success,
      '미지급': AppColors.error,
      '일부지급': AppColors.warning,
    };

    final entries = statusAmounts.entries.toList();
    final total = statusAmounts.values.fold<num>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: entries.map((e) {
                final pct = total > 0 ? (e.value / total * 100) : 0;
                return PieChartSectionData(
                  color: colors[e.key] ?? AppColors.grey,
                  value: e.value.toDouble(),
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                  radius: 60,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.map((e) {
            final color = colors[e.key] ?? AppColors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Text(e.key, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(width: 8),
                  Text('${_formatMoney(e.value)}원', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'DRAFT': return '초안';
      case 'SENT': return '발송';
      case 'PAID': return '지급완료';
      case 'UNPAID': return '미지급';
      case 'PARTIAL': return '일부지급';
      default: return raw.isNotEmpty ? raw : '기타';
    }
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTextStyles.titleLarge.copyWith(color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
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
}
