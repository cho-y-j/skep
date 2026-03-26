import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skep_app/core/constants/app_colors.dart';
import 'package:skep_app/core/constants/app_text_styles.dart';
import 'package:skep_app/core/constants/api_endpoints.dart';
import 'package:skep_app/core/network/dio_client.dart';

class BpDailyRosterPage extends StatefulWidget {
  const BpDailyRosterPage({Key? key}) : super(key: key);

  @override
  State<BpDailyRosterPage> createState() => _BpDailyRosterPageState();
}

class _BpDailyRosterPageState extends State<BpDailyRosterPage> {
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _roster = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
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
          _roster = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['content'] is List) {
          _roster = (data['content'] as List).cast<Map<String, dynamic>>();
        } else {
          _roster = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      _roster = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '승인':
        return AppColors.success;
      case '대기':
        return AppColors.warning;
      case '교체':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _mapRosterStatus(dynamic status) {
    final s = status?.toString().toUpperCase() ?? '';
    switch (s) {
      case 'APPROVED':
        return '승인';
      case 'PENDING':
        return '대기';
      case 'REJECTED':
      case 'REPLACEMENT':
        return '교체';
      default:
        return status?.toString() ?? '';
    }
  }

  Future<void> _approveAll() async {
    try {
      final dioClient = context.read<DioClient>();
      final pending = _roster.where((r) {
        final s = (r['status'] ?? '').toString().toUpperCase();
        return s == '대기' || s == 'PENDING';
      }).toList();
      for (final r in pending) {
        final id = r['id'];
        if (id != null) {
          await dioClient.put<dynamic>(
            ApiEndpoints.dailyRoster.replaceAll('{id}', id.toString()) + '/approve',
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전체 승인되었습니다.'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전체 승인 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _keepPrevious() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이전 명단이 유지됩니다.')),
    );
  }

  Future<void> _approveOne(int index) async {
    final id = _roster[index]['id'];
    if (id == null) return;
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        ApiEndpoints.dailyRoster.replaceAll('{id}', id.toString()) + '/approve',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('승인되었습니다.'), backgroundColor: AppColors.success),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _requestReplacement(int index) async {
    final id = _roster[index]['id'];
    if (id == null) return;
    try {
      final dioClient = context.read<DioClient>();
      await dioClient.put<dynamic>(
        ApiEndpoints.dailyRoster.replaceAll('{id}', id.toString()) + '/reject',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('교체 요청이 전송되었습니다.'), backgroundColor: AppColors.warning),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('교체 요청 실패: $e'), backgroundColor: AppColors.error),
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
          Text('일일 작업자 명단', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '익일 작업자 명단을 확인하고 승인합니다.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          // 날짜 선택 + 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('날짜: ', style: AppTextStyles.titleMedium),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) {
                      setState(() => _selectedDate = d);
                      _loadData();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_formatDate(_selectedDate),
                        style: AppTextStyles.bodyMedium),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _keepPrevious,
                  child: const Text('이전 명단 유지'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _approveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('전체 승인'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 명단 테이블
          if (_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('데이터를 불러오는데 실패했습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                  const SizedBox(height: 8),
                  Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _loadData, child: const Text('다시 시도')),
                ],
              ),
            )
          else if (_roster.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.grey),
                  const SizedBox(height: 12),
                  Text('해당 날짜의 명단이 없습니다', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('장비유형')),
                    DataColumn(label: Text('차량번호')),
                    DataColumn(label: Text('운전원')),
                    DataColumn(label: Text('유도원')),
                    DataColumn(label: Text('상태')),
                    DataColumn(label: Text('작업')),
                  ],
                  rows: List.generate(_roster.length, (i) {
                    final r = _roster[i];
                    final status = _mapRosterStatus(r['status'] ?? r['rosterStatus'] ?? '');
                    return DataRow(cells: [
                      DataCell(Text(r['equipType'] ?? r['equipmentType'] ?? r['equipmentName'] ?? '')),
                      DataCell(Text(r['plateNo'] ?? r['vehicleNumber'] ?? '')),
                      DataCell(Text(r['operator'] ?? r['operatorName'] ?? '')),
                      DataCell(Text(r['guide'] ?? r['guideName'] ?? '-')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
                      DataCell(status == '대기'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _approveOne(i),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.success),
                                  child: const Text('승인'),
                                ),
                                TextButton(
                                  onPressed: () => _requestReplacement(i),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('교체요청'),
                                ),
                              ],
                            )
                          : const Text('-')),
                    ]);
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
