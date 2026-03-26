import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class AdminSettlementPage extends StatefulWidget {
  const AdminSettlementPage({Key? key}) : super(key: key);

  @override
  State<AdminSettlementPage> createState() => _AdminSettlementPageState();
}

class _AdminSettlementPageState extends State<AdminSettlementPage> {
  List<Map<String, dynamic>> _settlements = [];
  bool _isLoading = true;
  String? _error;

  // Summary values
  num _totalAmount = 0;
  num _paidAmount = 0;
  num _unpaidAmount = 0;

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
      default: return status.isNotEmpty ? status : '-';
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case '지급완료': return AppColors.success;
      case '미지급': return AppColors.error;
      case '일부지급': return AppColors.warning;
      default: return AppColors.grey;
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
        // 월간 거래 합계 카드
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
        // 정산 상세 목록
        Text('정산 상세 목록', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _settlements.isEmpty
              ? Padding(
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
                )
              : SingleChildScrollView(
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
                      final amount = (s['amount'] ?? s['totalAmount'] ?? s['total_amount'] ?? 0) as num;
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
                ),
        ),
      ],
    );
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
