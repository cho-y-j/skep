import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class QuotationDetailPage extends StatefulWidget {
  final int requestId;
  final Map<String, dynamic>? requestInfo;

  const QuotationDetailPage({
    Key? key,
    required this.requestId,
    this.requestInfo,
  }) : super(key: key);

  @override
  State<QuotationDetailPage> createState() => _QuotationDetailPageState();
}

class _QuotationDetailPageState extends State<QuotationDetailPage> {
  List<Map<String, dynamic>> _quotations = [];
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requestData = widget.requestInfo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dioClient = context.read<DioClient>();
      final response = await dioClient.get<dynamic>(
        '/api/dispatch/quotations/request/${widget.requestId}',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List) {
          _quotations = data.cast<Map<String, dynamic>>();
        } else if (data is Map) {
          if (data['quotations'] is List) {
            _quotations = (data['quotations'] as List).cast<Map<String, dynamic>>();
          } else if (data['content'] is List) {
            _quotations = (data['content'] as List).cast<Map<String, dynamic>>();
          } else if (data['items'] is List) {
            _quotations = (data['items'] as List).cast<Map<String, dynamic>>();
          } else {
            _quotations = [];
          }
          // 요청 정보가 응답에 포함된 경우
          if (_requestData == null && data['request'] is Map) {
            _requestData = (data['request'] as Map).cast<String, dynamic>();
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      _quotations = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getStatus() {
    return _requestData?['status']?.toString() ?? '';
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return '임시저장';
      case 'SUBMITTED':
        return '제출됨';
      case 'ACCEPTED':
        return '승인됨';
      case 'REJECTED':
        return '거절됨';
      default:
        return status.isNotEmpty ? status : '-';
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return const Color(0xFF64748B);
      case 'SUBMITTED':
        return AppColors.primary;
      case 'ACCEPTED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      default:
        return Colors.grey;
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

  String _formatNumber(dynamic value) {
    if (value == null) return '-';
    try {
      final num n = value is num ? value : num.parse(value.toString());
      // 천 단위 콤마
      final str = n.toStringAsFixed(0);
      final buffer = StringBuffer();
      for (var i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0 && str[i] != '-') {
          buffer.write(',');
        }
        buffer.write(str[i]);
      }
      return buffer.toString();
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _submitQuotation() async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        '/api/dispatch/quotations/request/${widget.requestId}/submit',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 제출되었습니다.'), backgroundColor: AppColors.success),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _approveQuotation() async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        '/api/dispatch/quotations/request/${widget.requestId}/approve',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 승인되었습니다.'), backgroundColor: AppColors.success),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectQuotation() async {
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.post<dynamic>(
        '/api/dispatch/quotations/request/${widget.requestId}/reject',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적서가 거절되었습니다.'), backgroundColor: AppColors.warning),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '뒤로가기',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '견적서 상세',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text('견적 요청 #${widget.requestId}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
          const SizedBox(height: 20),
          // 본문
          _buildContent(),
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

    final status = _getStatus();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 견적 요청 정보
        _buildRequestInfoCard(status),
        const SizedBox(height: 16),
        // 견적 항목 테이블
        _buildQuotationTable(),
        const SizedBox(height: 16),
        // 액션 버튼
        _buildActionButtons(status),
        const SizedBox(height: 16),
        // 비고
        _buildNotesSection(),
      ],
    );
  }

  Widget _buildRequestInfoCard(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('견적 요청 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const Spacer(),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: _statusColor(status), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _infoItem('제목', _requestData?['title']?.toString() ?? '-'),
              _infoItem('현장', _requestData?['siteName']?.toString() ?? _requestData?['site']?.toString() ?? '-'),
              _infoItem('BP사', _requestData?['bpCompanyName']?.toString() ?? _requestData?['bpCompany']?.toString() ?? '-'),
              _infoItem('시작일', _formatDate(_requestData?['startDate'] ?? _requestData?['start_date'])),
              _infoItem('종료일', _formatDate(_requestData?['endDate'] ?? _requestData?['end_date'])),
              _infoItem('요청일', _formatDate(_requestData?['createdAt'] ?? _requestData?['created_at'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildQuotationTable() {
    if (_quotations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('견적 항목이 없습니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    // 합계 계산
    num totalDailyPrice = 0;
    num totalMonthlyPrice = 0;
    for (final q in _quotations) {
      final qty = _toNum(q['quantity'] ?? q['qty'] ?? 1);
      final daily = _toNum(q['dailyPrice'] ?? q['daily_price'] ?? q['dailyUnitPrice'] ?? 0);
      final monthly = _toNum(q['monthlyPrice'] ?? q['monthly_price'] ?? q['monthlyUnitPrice'] ?? 0);
      totalDailyPrice += qty * daily;
      totalMonthlyPrice += qty * monthly;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('견적 항목 (${_quotations.length}건)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              columns: const [
                DataColumn(label: Text('장비 종류')),
                DataColumn(label: Text('수량'), numeric: true),
                DataColumn(label: Text('일 단가'), numeric: true),
                DataColumn(label: Text('야간'), numeric: true),
                DataColumn(label: Text('월 단가'), numeric: true),
                DataColumn(label: Text('인건비 포함')),
                DataColumn(label: Text('기사 일당'), numeric: true),
                DataColumn(label: Text('유도원 일당'), numeric: true),
                DataColumn(label: Text('비고')),
              ],
              rows: [
                ..._quotations.map((q) {
                  return DataRow(cells: [
                    DataCell(Text(q['equipmentType']?.toString() ?? q['equipment_type']?.toString() ?? q['typeName']?.toString() ?? '-')),
                    DataCell(Text(_formatNumber(q['quantity'] ?? q['qty'] ?? '-'))),
                    DataCell(Text(_formatNumber(q['dailyPrice'] ?? q['daily_price'] ?? q['dailyUnitPrice'] ?? '-'))),
                    DataCell(Text(_formatNumber(q['nightPrice'] ?? q['night_price'] ?? q['nightUnitPrice'] ?? '-'))),
                    DataCell(Text(_formatNumber(q['monthlyPrice'] ?? q['monthly_price'] ?? q['monthlyUnitPrice'] ?? '-'))),
                    DataCell(Text((q['includesLabor'] == true || q['includes_labor'] == true) ? 'O' : 'X')),
                    DataCell(Text(_formatNumber(q['driverDailyPay'] ?? q['driver_daily_pay'] ?? '-'))),
                    DataCell(Text(_formatNumber(q['guidemanDailyPay'] ?? q['guideman_daily_pay'] ?? q['flagmanDailyPay'] ?? '-'))),
                    DataCell(Text(q['note']?.toString() ?? q['remark']?.toString() ?? q['remarks']?.toString() ?? '-')),
                  ]);
                }),
                // 합계 행
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                  cells: [
                    const DataCell(Text('합계', style: TextStyle(fontWeight: FontWeight.w700))),
                    const DataCell(Text('')),
                    DataCell(Text(_formatNumber(totalDailyPrice), style: const TextStyle(fontWeight: FontWeight.w700))),
                    const DataCell(Text('')),
                    DataCell(Text(_formatNumber(totalMonthlyPrice), style: const TextStyle(fontWeight: FontWeight.w700))),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final upperStatus = status.toUpperCase();

    if (upperStatus == 'ACCEPTED' || upperStatus == 'REJECTED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _statusColor(status).withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              upperStatus == 'ACCEPTED' ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: _statusColor(status),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              upperStatus == 'ACCEPTED' ? '이 견적서는 승인되었습니다.' : '이 견적서는 거절되었습니다.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _statusColor(status)),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (upperStatus == 'DRAFT') ...[
          ElevatedButton.icon(
            onPressed: _submitQuotation,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('제출'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
        if (upperStatus == 'SUBMITTED') ...[
          ElevatedButton.icon(
            onPressed: _rejectQuotation,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('거절'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _approveQuotation,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('승인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection() {
    final notes = _requestData?['notes']?.toString() ??
        _requestData?['remark']?.toString() ??
        _requestData?['remarks']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('비고', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Text(
            notes ?? '비고 없음',
            style: TextStyle(
              fontSize: 14,
              color: notes != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    try {
      return num.parse(value.toString());
    } catch (_) {
      return 0;
    }
  }
}
